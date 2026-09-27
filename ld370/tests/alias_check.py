#!/usr/bin/env python3
"""Compare the PDS directory of an ld370 unload with IEWL's own (#466).

    alias_check.py ORACLE.xmit CANDIDATE [--layout | --subset]

ORACLE is a TSO TRANSMIT of a load library IEWL wrote (fixtures/alias.iewl.xmit,
MVSCE-LAB JOB01367); CANDIDATE is an ld370 -iebcopy or -xmit.  Every entry must match by
name, and its C byte and user data must be byte-identical EXCEPT the two fields
that depend on where the member lies in the library: the entry's own TTR and
PDS2TTRT (user-data bytes 0-2).  An alias must carry its member's TTR.

--subset compares only the candidate's names (each must be in the oracle), for a
single link that produces one member and its aliases out of the oracle's seven.

--layout additionally requires the same directory blocks: the same number of
blocks, each holding the same names, with the same used count and key.  That is
the by-bytes packing: an alias entry is 46 bytes, a member's 36.

Only the directory is compared -- the member bytes are ld370's business
elsewhere in run.sh.  Exit 0 on a match, 1 with the differences listed.
"""
import sys

ENV_HDR = 328                     # COPYR1 + COPYR2


def netdata_records(b):
    """The data (non-control) logical records of a NETDATA stream."""
    i, recs, cur = 0, [], b""
    while i + 2 <= len(b):
        ln, fl = b[i], b[i + 1]
        if ln < 2:
            break
        data = b[i + 2:i + ln]
        i += ln
        if fl & 0x20:
            continue
        cur += data
        if fl & 0x40:
            recs.append(cur)
            cur = b""
    return recs


def unload_of_xmit(path):
    return b"".join(netdata_records(open(path, "rb").read()))


def directory(u):
    """[(used, key, [(name, ttr, c, ud), ...]), ...] for each directory block."""
    p, blocks = ENV_HDR, []
    while p + 12 <= len(u) and u[p + 9] == 8 and int.from_bytes(u[p + 10:p + 12], "big") == 256:
        key = u[p + 12:p + 20]
        blk = u[p + 20:p + 276]
        p += 276
        used = int.from_bytes(blk[0:2], "big")
        ents, q = [], 2
        while q + 12 <= used and blk[q] != 0xFF:
            c = blk[q + 11]
            n = (c & 0x1F) * 2
            ents.append((blk[q:q + 8].decode("cp037").rstrip(), blk[q + 8:q + 11], c,
                         blk[q + 12:q + 12 + n]))
            q += 12 + n
        blocks.append((used, key, ents))
    return blocks


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    layout, subset = "--layout" in argv, "--subset" in argv
    ora = directory(unload_of_xmit(argv[1]))
    raw = open(argv[2], "rb").read()
    cand = directory(raw if raw[1:4] == b"\xca\x6d\x0f" else unload_of_xmit(argv[2]))
    oe = {e[0]: e for b in ora for e in b[2]}
    ce = {e[0]: e for b in cand for e in b[2]}
    bad = []
    if not ce:
        bad.append("no directory entries in the candidate")
    if subset:
        if set(ce) - set(oe):
            bad.append("names not in the oracle: %s" % sorted(set(ce) - set(oe)))
    elif sorted(oe) != sorted(ce):
        bad.append("names differ: IEWL %s, ld370 %s" % (sorted(oe), sorted(ce)))
    for name in sorted(set(oe) & set(ce)):
        _, ottr, oc, oud = oe[name]
        _, cttr, cc, cud = ce[name]
        if oc != cc:
            bad.append("%-8s C byte: IEWL %02X, ld370 %02X" % (name, oc, cc))
        if oud[3:] != cud[3:]:
            bad.append("%-8s user data past PDS2TTRT:\n           IEWL  %s\n           ld370 %s"
                       % (name, oud[3:].hex().upper(), cud[3:].hex().upper()))
        if cc & 0x80:                                  # an alias: its member's TTR and PDS2TTRT
            mn = cud[24:32].decode("cp037").rstrip() if len(cud) >= 32 else ""
            if mn not in ce:
                bad.append("%-8s PDS2MNM names '%s', which is not in the directory" % (name, mn))
            elif ce[mn][1] != cttr or ce[mn][3][0:3] != cud[0:3]:
                bad.append("%-8s TTR/PDS2TTRT %s/%s differ from its member %s's %s/%s"
                           % (name, cttr.hex(), cud[0:3].hex(), mn, ce[mn][1].hex(), ce[mn][3][0:3].hex()))
    if layout:
        shape = lambda bl: [(u, k.hex(), [e[0] for e in es]) for u, k, es in bl]
        if shape(ora) != shape(cand):
            bad.append("directory blocks differ:\n           IEWL  %s\n           ld370 %s"
                       % (shape(ora), shape(cand)))
    if bad:
        for b in bad:
            print("  FAIL: " + b)
        return 1
    print("  OK: %d entries == IEWL (masked at TTR/PDS2TTRT)%s"
          % (len(ce), ", %d blocks laid out as IEWL's" % len(cand) if layout else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
