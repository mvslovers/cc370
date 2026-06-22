#!/usr/bin/env python3
"""Structural check for an XMIT (TSO TRANSMIT / NETDATA) emitted by ld370 --xmit.

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

    if ok:
        print("  OK: FB80, INMR01/02/03/06 present, payload == unload image")
    return ok


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    return 0 if check(argv[1], argv[2]) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
