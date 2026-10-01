#!/usr/bin/env python3
"""Check an ld370 --map --xref against the member it describes.

Every reference row (`  +OFFSET  CON  SYMBOL  ADDRESS  in SECTION`) must name
an RLD item of the member at section origin + OFFSET whose R pointer is the
CESD entry SYMBOL, and when it resolved, the relocated adcon in the member's
text must hold ADDRESS.  The member is read with lmdiff.parse -- not by
ld370 -- so the map is not checking itself (cc370#9).

Usage: xref_check.py MEMBER MAP
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lmdiff import e2a, parse, u24  # noqa: E402


def main():
    b = open(sys.argv[1], 'rb').read()
    recs = parse(b)
    # Every CESD record, not only the first: lmdiff.parse reads one, and a real
    # module has several (HTTPD: an R pointer of 36 behind a 15-entry record).
    ent, p = {}, 0
    while p + 8 <= len(b) and b[p] & 0xF0 == 0x20:
        first, cnt = (b[p + 4] << 8) | b[p + 5], (b[p + 6] << 8) | b[p + 7]
        for i, e in enumerate(range(p + 8, p + 8 + cnt, 16)):
            ent[first + i] = {"name": e2a(b[e:e + 8]).rstrip(), "type": b[e + 8], "addr": u24(b, e + 9)}
        p += 8 + cnt
    image, rld = {}, {}
    for i, r in enumerate(recs):
        items = r.get("rld", []) + r.get("items", [])
        for it in items:
            rld.setdefault(it["addr"], []).append(it)
        if r["kind"] == "CTRL":
            load = u24(b, r["off"] + 9)            # CCW data address: where the text loads
            t = recs[i + 1]
            for k in range(t["len"]):
                image[load + k] = b[t["off"] + k]

    rows = 0
    sect_org = None
    for line in open(sys.argv[2]):
        line = line.rstrip("\n")
        m = re.match(r"^(\S.{7}|\s{8})  (SD|PC|CM)\s+([0-9A-F]{6})\s", line)
        if m:
            sect_org = int(m.group(3), 16)
            continue
        m = re.match(r"^  \+([0-9A-F]{6})  (\S+)\s+(\S+)\s+(.*)$", line)
        if not m:
            continue
        off, sym, rest = int(m.group(1), 16), m.group(3), m.group(4)
        at = sect_org + off
        a = re.match(r"([0-9A-F]{6})  in (PC ([0-9A-F]{6})|(\S+))$", rest)
        if a and a.group(3):                       # in an unnamed private-code section
            want = lambda e: e["type"] & 0x0F == 0x04 and e["addr"] == int(a.group(3), 16)
        elif a:
            want = lambda e: e["name"] == a.group(4) and e["type"] & 0x0F in (0x00, 0x04, 0x05)
        else:                                      # unresolved: the ER/WX itself
            want = lambda e: e["name"] == sym
        hit = [it for it in rld.get(at, []) if it["R"] in ent and want(ent[it["R"]])]
        if not hit:
            print("  FAIL: no RLD item at %06X against %s: %s" % (at, rest, line))
            return 1
        if a:
            n = ((hit[0]["flag"] >> 2) & 3) + 1
            val = int.from_bytes(bytes(image.get(at + k, 0) for k in range(n)), "big")
            if val != int(a.group(1), 16):
                print("  FAIL: adcon at %06X holds %06X, map says %s: %s" % (at, val, a.group(1), line))
                return 1
        rows += 1
    if rows == 0:
        print("  FAIL: no reference rows in the map")
        return 1
    print("  xref rows == member RLD + adcons: %d" % rows)
    return 0


if __name__ == '__main__':
    sys.exit(main())
