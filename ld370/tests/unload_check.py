#!/usr/bin/env python3
"""Structural check for an IEBCOPY unloaded image emitted by ld370 --unload.

Parses the unload by its own CKD count fields and asserts:
  - the directory entries are in ascending EBCDIC-name order (PDS requirement),
  - the named members reconstruct byte-for-byte from their directory TTR record
    onward (so split_member tiled each member correctly), and
  - the record stream consumes exactly to EOF (no desync / trailing slack).

This guards split_member + emit_unload host-side.  It does NOT prove the image
reloads on MVS -- that is the IEBCOPY LOAD oracle (Stage 2).

Usage:  unload_check.py UNLOAD  NAME1=MEMBER1.lm [NAME2=MEMBER2.lm ...]
Exit 0 on success, 1 on any mismatch.
"""
import sys

ENV_HDR = 328  # COPYR1 + COPYR2


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def e2a(e):
    t = {0xC1 + i: chr(ord('A') + i) for i in range(9)}
    t.update({0xD1 + i: chr(ord('J') + i) for i in range(9)})
    t.update({0xE2 + i: chr(ord('S') + i) for i in range(8)})
    t.update({0xF0 + i: chr(ord('0') + i) for i in range(10)})
    t[0x40] = ' '
    return t.get(e, '?')


def check(unload_path, expect):
    u = open(unload_path, 'rb').read()
    p = ENV_HDR

    # directory record: count12 (KL=8, DL=256) + key(8) + 256-byte block
    kl, dl = u[p + 9], be16(u, p + 10)
    if kl != 8 or dl != 256:
        print("  FAIL: directory count KL=%d DL=%d (want 8/256)" % (kl, dl))
        return False
    block = u[p + 20:p + 20 + 256]
    p += 12 + 8 + 256

    used = be16(block, 0)
    entries, q = [], 2
    while q < used and block[q] != 0xFF:
        name = ''.join(e2a(c) for c in block[q:q + 8]).rstrip()
        tt = be16(block, q + 8)          # TTR = relative track (one block/track)
        entries.append((name, tt))
        q += 12 + (block[q + 11] & 0x1F) * 2

    if [n for n, _ in entries] != sorted(n for n, _ in entries):
        print("  FAIL: directory not name-sorted: %s" % [n for n, _ in entries])
        return False

    # end-of-directory marker record (12 zero bytes)
    if u[p:p + 12] != bytes(12):
        print("  FAIL: end-of-directory marker not zero")
        return False
    p += 12

    # member-data records: one block per relative track (R=1), in member/track
    # order, until the EOM (DL=0).  Block g sits on relative track g, so the
    # directory's TT indexes directly into this list.
    blocks = []
    while p + 12 <= len(u):
        kl, dl = u[p + 9], be16(u, p + 10)
        p += 12
        if dl == 0:                       # EOM
            break
        blocks.append(u[p:p + dl])
        p += kl + dl
    if p != len(u):
        print("  FAIL: stream did not consume to EOF (%d of %d)" % (p, len(u)))
        return False

    starts = sorted(tt for _, tt in entries)
    ok = True
    for name, tt in entries:
        nxt = min([s for s in starts if s > tt], default=len(blocks))
        blk = b''.join(blocks[tt:nxt])
        want = expect.get(name)
        if want is None:
            print("  FAIL: unexpected member '%s'" % name)
            ok = False
        elif blk != want:
            print("  FAIL: member '%s' reconstruct mismatch (%d vs %d bytes)" % (name, len(blk), len(want)))
            ok = False
    for name in expect:
        if name not in [n for n, _ in entries]:
            print("  FAIL: missing member '%s'" % name)
            ok = False
    if ok:
        print("  OK: %d member(s) reconstruct, dir sorted, EOF clean" % len(entries))
    return ok


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    expect = {}
    for spec in argv[2:]:
        name, _, path = spec.partition('=')
        expect[name] = open(path, 'rb').read()
    return 0 if check(argv[1], expect) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
