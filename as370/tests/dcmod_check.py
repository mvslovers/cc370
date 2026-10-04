#!/usr/bin/env python3
"""Compare as370's deck for tests/dcmod.s with IFOX00's, one region at a time.

The fixture spans three issues (#782 fixed-point exponent modifier, #761
floating-point scale, the floating-point exponent modifier); each region is
switched on as its issue lands, so a region that is not yet implemented cannot
fail the suite and one that is cannot regress unseen.

    dcmod_check.py AS370 REGION...
"""
import os, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REGIONS = {                          # name: (first, last+1, what)
    "fixed": (0x34, 0x68, "F/H exponent modifier (#782)"),
    "fscale": (0x00, 0x34, "E/D/L scale modifier (#761)"),
    "fexp": (0x68, 0x88, "E/D/L exponent modifier"),
}


def image(path):
    d = open(path, "rb").read()
    im = {}
    for i in range(0, len(d), 80):
        c = d[i:i + 80]
        if c[1:4] == b"\xe3\xe7\xe3":                     # TXT
            a = int.from_bytes(c[5:8], "big")
            n = int.from_bytes(c[10:12], "big")
            for k in range(n):
                im[a + k] = c[16 + k]
    return im


def main():
    as370, names = sys.argv[1], sys.argv[2:]
    with tempfile.TemporaryDirectory() as td:
        out = os.path.join(td, "dcmod.obj")
        subprocess.run([as370, os.path.join(HERE, "dcmod.s"), "-o", out], capture_output=True)
        mine = image(out) if os.path.exists(out) else {}
    ref = image(os.path.join(HERE, "ref", "dcmod.obj"))
    bad = 0
    for nm in names:
        lo, hi, what = REGIONS[nm]
        diff = [a for a in range(lo, hi) if mine.get(a) != ref.get(a)]
        if diff:
            print(f"dcmod {nm}: FAIL -- {what}: {len(diff)} bytes differ from IFOX00, first at X'{diff[0]:X}'")
            bad = 1
        else:
            print(f"dcmod {nm}: OK ({what}: X'{lo:X}'-X'{hi - 1:X}' == IFOX00)")
    return bad


if __name__ == "__main__":
    sys.exit(main())
