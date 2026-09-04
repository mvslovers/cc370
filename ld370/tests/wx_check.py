#!/usr/bin/env python3
"""Read a symbol's ESD type byte out of a load module's composite ESD (CESD).

Guards issue #99 from both sides: a WX matched by a hard ER must be promoted to
ER (and so reported unresolved), while a WX matched by nothing -- or only by
another WX -- must stay type 0x0A, which is the whole point of a weak external
and the mechanism the entry-point work rests on.

Walks the CESD records rather than scanning for the name at a fixed offset: the
member opens with one or more records whose first byte is 0x2x, an 8-byte header
(off 4-5 = ESD-ID of the first entry, off 6-7 = 16 x entries), then 16-byte
entries -- name (8, EBCDIC, blank padded), type (1), ...

usage: wx_check.py MEMBER SYM=HEXTYPE [SYM=HEXTYPE ...]
"""
import sys


def cesd_types(path):
    m = open(path, "rb").read()
    out, p = {}, 0
    while p + 8 <= len(m) and (m[p] & 0xF0) == 0x20:
        n = (m[p + 6] << 8) | m[p + 7]
        if n == 0 or p + 8 + n > len(m):
            break
        for k in range(n // 16):
            e = m[p + 8 + k * 16 : p + 8 + (k + 1) * 16]
            out[e[:8].decode("cp037").rstrip()] = e[8]
        p += 8 + n
    return out


def main(argv):
    if len(argv) < 3:
        sys.exit(__doc__)
    have, bad = cesd_types(argv[1]), 0
    for spec in argv[2:]:
        sym, _, want = spec.partition("=")
        want = int(want, 16)
        got = have.get(sym)
        if got is None:
            print("  FAIL: %s not in the CESD (have: %s)" % (sym, sorted(have)))
            bad = 1
        elif got != want:
            print("  FAIL: %s CESD type %02X, expected %02X" % (sym, got, want))
            bad = 1
        else:
            print("  OK: %s CESD type %02X" % (sym, got))
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv))
