"""Assert what --sparse-text may and may not drop, from the object deck itself.

A size comparison cannot tell a correctly elided DS reservation from a
wrongly elided run of written zeros -- both shrink the member, and in the
loaded module both regions are the same bytes.  The distinction lives in
the object deck: a TXT card covers the zeros a programmer wrote, and
nothing covers a DS gap.  So this reads the deck for ground truth and
checks the member against it, rather than against offsets baked in here
that would drift the moment the fixture changed.

    sparse_scan.py DECK.o MEMBER_FLAG_OFF MEMBER_FLAG_ON

Rules checked:
  1. flag off  -- every byte of the section's extent is covered.  The
     default must stay byte-faithful to IEWL, which materialises gaps.
  2. flag on   -- every byte a TXT card defined is STILL covered.  This is
     the one #445 broke: its predicate was the byte value, so it dropped
     DC X'00' along with the reservations.
  3. flag on   -- at least one record is actually gone, or the fixture has
     stopped exercising the flag and the other two rules prove nothing.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import lmdiff


def u16(b, o): return (b[o] << 8) | b[o + 1]
def u24(b, o): return (b[o] << 16) | (b[o + 1] << 8) | b[o + 2]


def deck_defined(deck):
    """Byte ranges some TXT card covered, and the section extent, from an
    80-column object deck.  ESD gives the extent, TXT gives the coverage."""
    defined, extent = [], 0
    for p in range(0, len(deck) - 79, 80):
        c = deck[p:p + 80]
        if c[0] != 0x02:
            continue
        kind = bytes(c[1:4])
        if kind == b'\xe3\xe7\xe3':                       # TXT
            addr, cnt = u24(c, 5), u16(c, 10)
            if cnt:
                defined.append((addr, cnt))
        elif kind == b'\xc5\xe2\xc4':                     # ESD
            n = u16(c, 10)
            for i in range(0, n, 16):
                e = c[16 + i:32 + i]
                if len(e) == 16 and e[8] in (0x00, 0x04, 0x05):   # SD/PC/CM
                    extent = max(extent, u24(e, 13))
    return defined, extent


def member_covered(mod):
    """Byte ranges a member's text records cover, from its control records."""
    out = []
    for r in lmdiff.parse(mod):
        if r["kind"] == "CTRL" and r["textlen"]:
            out.append((u24(mod, r["off"] + 9), r["textlen"]))
    return out


def as_set(ranges):
    s = set()
    for a, n in ranges:
        s.update(range(a, a + n))
    return s


def main():
    deck = open(sys.argv[1], 'rb').read()
    off = open(sys.argv[2], 'rb').read()
    on = open(sys.argv[3], 'rb').read()

    defined, extent = deck_defined(deck)
    dset = as_set(defined)
    off_cov, on_cov = member_covered(off), member_covered(on)
    oset, nset = as_set(off_cov), as_set(on_cov)
    fails = 0

    print(f"  deck: extent {extent}, {len(dset)} bytes covered by TXT cards, "
          f"{extent - len(dset)} reserved")

    # The member may cover a little MORE than the deck's extent -- ld370
    # pads sections up to a boundary -- so this is a floor, not equality.
    missing = sorted(set(range(extent)) - oset)
    if missing:
        print(f"  FAIL: flag off leaves {len(missing)} bytes of the extent "
              f"uncovered, first at {missing[0]}")
        fails += 1
    else:
        print(f"  OK: flag off covers the whole {extent}-byte extent "
              f"({len(off_cov)} text records, {len(oset) - extent} bytes of padding)")

    lost = dset - nset
    if lost:
        lo = min(lost)
        print(f"  FAIL: --sparse-text dropped {len(lost)} bytes a TXT card "
              f"defined, first at {lo} (0x{lo:X}) -- written zeros are text")
        fails += 1
    else:
        print(f"  OK: --sparse-text kept every one of the {len(dset)} defined "
              f"bytes ({len(on_cov)} text records)")

    dropped = len(oset) - len(nset)
    if dropped <= 0:
        print("  FAIL: --sparse-text dropped nothing; the fixture no longer "
              "exercises the flag")
        fails += 1
    else:
        print(f"  OK: --sparse-text elided {dropped} bytes no TXT card covered")

    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
