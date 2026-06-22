#!/usr/bin/env python3
"""Turn a multi-member -iebcopy image into a BROKEN single-EOM layout: drop every
per-member DL=0 EOF except the final one, so member 1 runs into member 2's data.

This is a SIM SANITY CHECK, not a model of any real failure: feeding the result
to unload_check.py and requiring a NON-zero exit proves the simulator detects a
member running past its end rather than merely slicing members back out.  It is
NOT the layout that abended on MVS -- the multi-member round-trips failed in the
XMIT *transport* (members packed into one RECFM=VS record; see xmit_check.py's
per-member-framing guard), which the unload-image simulator cannot see at all.

Usage:  strip_interior_eof.py IN.iebcopy OUT.iebcopy
"""
import sys

ENV_HDR = 328


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def main(src, dst):
    u = open(src, 'rb').read()
    p = ENV_HDR + 12 + 8 + 256          # past COPYR1/2 + directory record
    p += 12                             # past end-of-directory marker
    head = u[:p]
    recs = []
    while p + 12 <= len(u):
        kl, dl = u[p + 9], be16(u, p + 10)
        recs.append(u[p:p + 12 + kl + dl])
        p += 12 + kl + dl
    out = bytearray(head)
    for i, r in enumerate(recs):
        if be16(r, 10) == 0 and i != len(recs) - 1:   # interior DL=0 EOF -> drop
            continue
        out += r
    open(dst, 'wb').write(out)
    print("  built single-EOM image: %d -> %d bytes (interior EOFs dropped)"
          % (len(u), len(out)))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(2)
    main(sys.argv[1], sys.argv[2])
