#!/usr/bin/env python3
"""Structural check for an XMIT (TSO TRANSMIT / NETDATA) emitted by ld370 --xmit.

Reassembles the NETDATA segment stream and asserts, against the TRANSMIT oracle
and the IEBCOPY-unload oracle:
  - RECFM=FB80 (length a multiple of 80) and the expected 9 logical records,
  - the INMR control records (INMR01/02/02/03/06) are byte-identical to the
    oracle's, MODULO the INMFTIME timestamp (an inherent carve-out, like the
    IDR date), and
  - the 4 data records concatenate to exactly the IEBCOPY-unload image (the
    wrapper carries the payload byte-faithfully).

The oracle's embedded unload has a different volume geometry than ld370's
echoed one, so the *payload* is compared to the unload oracle, not to the
TRANSMIT oracle's payload.  This proves the wrapper; RECEIVE+run proves install.

Usage:  xmit_check.py HOST.xmit  ORACLE.xmit  UNLOAD.bin
Exit 0 on success, 1 on mismatch.
"""
import sys

INMFTIME_OFF = 0x49   # offset of the 16-byte INMFTIME value within INMR01


def logrecs(x):
    """reassemble NETDATA segments into logical records"""
    out, p, cur = [], 0, b''
    while p + 2 <= len(x):
        seglen, flags = x[p], x[p + 1]
        if seglen < 2:
            p += 1
            continue
        cur += x[p + 2:p + seglen]
        p += seglen
        if flags & 0x40:
            out.append(cur)
            cur = b''
    return out


def check(host_path, oracle_path, unload_path):
    host = open(host_path, 'rb').read()
    oracle = open(oracle_path, 'rb').read()
    unload = open(unload_path, 'rb').read()

    if len(host) % 80 != 0:
        print("  FAIL: host XMIT length %d not a multiple of 80" % len(host))
        return False

    hr, orr = logrecs(host), logrecs(oracle)
    if len(hr) != 9 or len(orr) != 9:
        print("  FAIL: logical record count host=%d oracle=%d (want 9)" % (len(hr), len(orr)))
        return False

    ok = True
    # INMR records are logical records 0,1,2,3 and 8; payload is 4..7
    for i in (0, 1, 2, 3, 8):
        a, b = hr[i], orr[i]
        if i == 0:  # blank the timestamp before comparing
            a = a[:INMFTIME_OFF] + b'\x00' * 16 + a[INMFTIME_OFF + 16:]
            b = b[:INMFTIME_OFF] + b'\x00' * 16 + b[INMFTIME_OFF + 16:]
        if a != b:
            print("  FAIL: INMR logical record %d differs from oracle" % i)
            ok = False

    payload = b''.join(hr[4:8])
    if payload != unload:
        print("  FAIL: XMIT payload (%d B) != unload oracle (%d B)" % (len(payload), len(unload)))
        ok = False

    if ok:
        print("  OK: FB80, 9 records, INMR == oracle (modulo timestamp), payload == unload")
    return ok


def main(argv):
    if len(argv) != 4:
        print(__doc__)
        return 2
    return 0 if check(argv[1], argv[2], argv[3]) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
