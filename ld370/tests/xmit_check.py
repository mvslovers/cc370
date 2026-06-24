#!/usr/bin/env python3
"""Structural check for an XMIT (TSO TRANSMIT / NETDATA) emitted by ld370 -xmit.

Reassembles the NETDATA segment stream and asserts:
  - RECFM=FB80 (length a multiple of 80),
  - the control stream carries INMR01 / INMR02 / INMR03 / INMR06 records, and
  - the data (non-INMR) records concatenate to exactly the unload image passed
    in -- i.e. the wrapper carries the payload byte-faithfully.

Byte-identity to a *real* TSO TRANSMIT oracle no longer applies: ld370's unload
is deliberately one-block-per-track (device-agnostic), which a real IEBCOPY
unload never is, so the only sound payload reference is ld370's own unload of the
same member.  The real end-to-end oracle is RECV370 LOAD + run on MVS (RC=7).

Usage:  xmit_check.py HOST.xmit  UNLOAD.bin
Exit 0 on success, 1 on mismatch.
"""
import sys

INMR = bytes([0xC9, 0xD5, 0xD4, 0xD9])   # 'INMR' in EBCDIC


def logrecs_typed(x):
    """reassemble NETDATA segments -> list of (is_control, bytes)."""
    out, p, cur, ctl = [], 0, b'', False
    while p + 2 <= len(x):
        seglen, flags = x[p], x[p + 1]
        if seglen < 2:
            p += 1
            continue
        cur += x[p + 2:p + seglen]
        if flags & 0x20:
            ctl = True
        p += seglen
        if flags & 0x40:                 # last segment of record
            out.append((ctl, cur))
            cur, ctl = b'', False
    return out


def check(host_path, unload_path):
    host = open(host_path, 'rb').read()
    unload = open(unload_path, 'rb').read()
    ok = True

    if len(host) % 80 != 0:
        print("  FAIL: host XMIT length %d not a multiple of 80" % len(host))
        return False

    recs = logrecs_typed(host)
    names = [bytes(r[:6]).decode('cp037') for c, r in recs if c and r[:4] == INMR]
    for want in ('INMR01', 'INMR02', 'INMR03', 'INMR06'):
        if want not in names:
            print("  FAIL: missing control record %s (have %s)" % (want, names))
            ok = False

    payload = b''.join(r for c, r in recs if not c)
    if payload != unload:
        print("  FAIL: XMIT payload (%d B) != unload image (%d B)" % (len(payload), len(unload)))
        ok = False

    def be16(b, o):
        return (b[o] << 8) | b[o + 1]

    # INMSIZE (INMR02 #1 = IEBCOPY) sizes the target load library; TSO/NJE38 RECEIVE
    # allocates the target dataset from it, so a hardcoded constant SB37s a large
    # multi-module pack (the rexx370 deploy hit this).  It must equal the member-data
    # region = the unload minus the env header, the directory blocks and the EOD
    # marker -- i.e. scale with the actual package, never a fixed value.
    def tu_int(rec, key):                       # decode an integer text unit's value
        p = 10                                  # past 'INMR02' eyecatcher (6) + file number (4)
        while p + 4 <= len(rec):
            k, num = be16(rec, p), be16(rec, p + 2); p += 4
            vl = be16(rec, p)
            if k == key:
                v = 0
                for j in range(vl):
                    v = (v << 8) | rec[p + 2 + j]
                return v
            t = p
            for _ in range(num or 1):
                if t + 2 > len(rec):
                    break
                t += 2 + be16(rec, t)
            p = t
        return None
    inmr02 = [r for c, r in recs if c and bytes(r[:6]).decode('cp037', 'replace') == 'INMR02']
    inmsize = tu_int(inmr02[0], 0x102c) if inmr02 else None   # first INMR02 = IEBCOPY
    q = ENV_HDR = 328
    while q + 12 <= len(unload) and unload[q + 9] == 8 and be16(unload, q + 10) == 256:
        q += 12 + 8 + 256                       # directory block records
    q += 12                                     # end-of-directory marker
    member_data = len(unload) - q
    if inmsize is None:
        print("  FAIL: no INMSIZE in INMR02"); ok = False
    elif inmsize != member_data:
        print("  FAIL: INMSIZE %d != member-data %d B -> RECEIVE would mis-size the "
              "target (SB37 on a large pack)" % (inmsize, member_data)); ok = False

    # transport guard: IEBCOPY LOAD reads SYSUT1 one VS logical record at a time;
    # a member's data packed BEHIND another member's DL=0 EOF in the same logical
    # record is lost on reload (every 2-member layout abended IEB183I this way,
    # regardless of unload geometry -- the sim cannot see this, it works on the
    # unload image, not the XMIT framing).  Assert no count-record follows a DL=0
    # within one data logical record.  (COPYR1/COPYR2 are raw env-header records,
    # not count-prefixed, so skip the 328-byte header.)
    off, packed = 0, False
    for c, r in recs:
        if c:
            continue
        start, off = off, off + len(r)
        if start < ENV_HDR:                 # COPYR1 / COPYR2 (no count field)
            continue
        q, saw_eof = 0, False
        while q + 12 <= len(r):
            if saw_eof:                     # a count-record follows a DL=0 -> packed
                packed = True
                break
            kl, dl = r[q + 9], be16(r, q + 10)
            if dl == 0:
                saw_eof = True
            q += 12 + kl + dl
        if packed:
            break
    if packed:
        print("  FAIL: member data packed behind a DL=0 EOF in one VS record "
              "-> reload loses members after the first (IEB183I)")
        ok = False

    if ok:
        print("  OK: FB80, INMR01/02/03/06 present, payload == unload, per-member VS framing")
    return ok


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    return 0 if check(argv[1], argv[2]) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
