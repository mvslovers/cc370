#!/usr/bin/env python3
"""RLD record invariant check on a bare load-module member.

Walks the record stream (CESD / IDR / control+text / RLD) and, for every RLD
record, walks its items via the SAMERP continuation bit.  The continuation bit
(0x01, "next item shares this R/P") must never survive onto a record's LAST
item: program fetch reads each record into a fresh buffer, so a set bit there
claims an item that does not exist in the record.  IEWL never emits it (0 of
50 records over SYS1.LINKLIB); ld370 used to inherit it verbatim from the
input object's RLD cards when a record filled to RLDMAX exactly (issue #41 --
the stray bit made libc370's __loadhi() read past the record data, S0C4).

Usage: rld_check.py MEMBER [MIN_RLD_RECORDS]
  MIN_RLD_RECORDS (default 2) guards against a vacuous pass: the boundary can
  only be exercised if the RLD data actually spans multiple records.
"""
import sys


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def main():
    member = sys.argv[1]
    min_recs = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    b = open(member, 'rb').read()
    n = len(b)
    p = 0
    while p < n and (b[p] & 0xF0) == 0x20:            # CESD records
        p += 8 + be16(b, p + 6)
    while p < n and b[p] == 0x80:                     # IDR records
        p += b[p + 1] + 1
    nrec = bad = 0
    while p < n:
        lo = b[p] & 0x0F
        if lo in (0x01, 0x05, 0x0D):                  # control (+ text follows)
            p += 16 + be16(b, p + 4) + be16(b, p + 14)
        elif lo in (0x02, 0x06, 0x0E):                # RLD record
            dlen = be16(b, p + 6)
            d = b[p + 16:p + 16 + dlen]
            q = 0
            cont = 0
            flag = None
            while q < dlen:
                if not cont:
                    q += 4                            # R/P prefix
                if q + 4 > dlen:
                    print("  FAIL: RLD record @%06X: item truncated at "
                          "offset %d of %d" % (p, q, dlen))
                    return 1
                flag = d[q]
                cont = flag & 0x01
                q += 4
            nrec += 1
            if flag is not None and flag & 0x01:
                print("  FAIL: RLD record @%06X (%d data bytes): last item "
                      "carries the continuation bit (flag %02X)" % (p, dlen, flag))
                bad += 1
            p += 16 + dlen
        else:
            print("  FAIL: unknown record type %02X @%06X" % (b[p], p))
            return 1
    if nrec < min_recs:
        print("  FAIL: only %d RLD record(s) -- boundary not exercised "
              "(need >= %d)" % (nrec, min_recs))
        return 1
    if bad:
        print("  %d of %d RLD record(s) end on a claimed continuation" % (bad, nrec))
        return 1
    print("  OK: %d RLD records, no record's last item claims a continuation" % nrec)
    return 0


if __name__ == '__main__':
    sys.exit(main())
