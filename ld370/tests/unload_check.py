#!/usr/bin/env python3
"""Faithful IEBCOPY/RECV370 reload simulator for ld370 -iebcopy images.

Earlier this script reconstructed each member by slicing the block list between
adjacent directory TTRs.  That is NOT how MVS reloads an unloaded PDS, and it
passed a broken multi-member layout that abended on the real system.  This
version reproduces the actual IEBCOPY LOAD member-find path, read straight off
the MVS 3.8j source (IEBRSAM / IEBDSCPY / IEBLDUL):

  * positioning -- the directory TTR (relative track, record) is converted to an
    absolute MBBCCHHR through the UDEBX extent's start (CC,HH) read FROM the
    image header (DEBSTRCC off 74 / DEBSTRHH off 76; 3350 = 30 trk/cyl), then R
    is decremented by 1 (IEBDSCPY.ASM:942 `IC/BCTR/STC REC`).  IEBRSAM then reads
    FORWARD (sequential QSAM, no rewind) and takes the first record whose full
    8-byte MBBCCHHR is > FDAD (IEBRSAM.ASM:381 `CLC 1(8,@1),FDAD` / `BC 12`).
  * member end -- the first in-band record with DL=0 terminates the member and
    is not part of its data (IEBRSAM.ASM:404 `CLC 10(2),=0000` -> sets RDEOF).
  * load end -- directory-driven: after the last directory entry the load is
    complete (IEBDSCPY.ASM:1026 `TLSTCPYD TM FLG4,LE`).  A member read that runs
    off the end of the record stream before a DL=0 is the IEB183I "END OF FILE
    READ ON LOAD DATA SET" abend the broken layout hit.

Reading the geometry from the header makes the check geometry-AGNOSTIC: it
validates ld370's echoed 0x8d layout AND a real IEBCOPY UNLOAD oracle (start
CC 0x178) with the same code -- so e2e2.iebcopy-unload.bin is a real positive
control (the thing the earlier negative-control-only simulator lacked, which is
why it falsely passed a layout MVS rejected).

Usage:  unload_check.py UNLOAD  NAME1[=MEMBER1.lm] [NAME2[=MEMBER2.lm] ...]
  A NAME without =FILE checks only that the member RELOADS (find + clean DL=0
  EOF), not its bytes -- used for the IEWL oracle, whose member bytes differ
  from ld370's.  Exit 0 on success, 1 on any mismatch.
"""
import sys

ENV_HDR = 328       # COPYR1 + COPYR2
TRKPERCYL = 30      # UNLOAD_TRKPERCYL (3350)


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def e2a(e):
    t = {0xC1 + i: chr(ord('A') + i) for i in range(9)}
    t.update({0xD1 + i: chr(ord('J') + i) for i in range(9)})
    t.update({0xE2 + i: chr(ord('S') + i) for i in range(8)})
    t.update({0xF0 + i: chr(ord('0') + i) for i in range(10)})
    t[0x40] = ' '
    return t.get(e, '?')


def fdad(u, tt, r):
    """Directory TTR (relative track, record) -> FDAD after IEBDSCPY's R-1, as
    the 8-byte M BB CC HH R count key (bytes, for the CLC compare).  The extent
    start (CC,HH) is read from the image's UDEBX header so the same convert MVS
    uses is applied -- a desync between directory and data area is caught exactly
    as the real reload would."""
    strcc, strhh = be16(u, 74), be16(u, 76)
    abstrk = strhh + tt
    cc = strcc + abstrk // TRKPERCYL
    hh = abstrk % TRKPERCYL
    return bytes([0, 0, 0, (cc >> 8) & 0xff, cc & 0xff,
                  (hh >> 8) & 0xff, hh & 0xff, (r - 1) & 0xff])


def check(unload_path, expect):
    u = open(unload_path, 'rb').read()
    p = ENV_HDR

    # --- directory: one or more count12(KL=8,DL=256)+key(8)+256B blocks, in
    #     ascending-name order, ending at the FF terminator in the last block ---
    entries = []
    while p + 12 <= len(u) and u[p + 9] == 8 and be16(u, p + 10) == 256:
        block = u[p + 20:p + 20 + 256]
        p += 12 + 8 + 256
        used = be16(block, 0)
        q = 2
        while q + 12 <= used and block[q] != 0xFF:
            name = ''.join(e2a(c) for c in block[q:q + 8]).rstrip()
            entries.append((name, be16(block, q + 8), block[q + 10]))   # name, TT, R
            q += 12 + (block[q + 11] & 0x1F) * 2
    if not entries:
        print("  FAIL: no directory entries")
        return False
    if [n for n, _, _ in entries] != sorted(n for n, _, _ in entries):
        print("  FAIL: directory not name-sorted: %s" % [n for n, _, _ in entries])
        return False

    # --- end-of-directory marker record (12 zero bytes) ---
    if u[p:p + 12] != bytes(12):
        print("  FAIL: end-of-directory marker not zero")
        return False
    p += 12

    # --- member-data records: (8-byte MBBCCHHR key, DL, data) in file order ---
    recs = []
    while p + 12 <= len(u):
        key = u[p + 1:p + 9]                      # M BB CC HH R
        kl, dl = u[p + 9], be16(u, p + 10)
        p += 12
        recs.append((key, dl, u[p:p + dl]))
        p += kl + dl
    if p != len(u):
        print("  FAIL: record stream did not consume to EOF (%d of %d)" % (p, len(u)))
        return False

    # --- reload simulation: sequential forward cursor, directory-driven ---
    ok = True
    cur = 0                                       # QSAM read position (no rewind)
    for name, tt, r in entries:
        want_fdad = fdad(u, tt, r)
        while cur < len(recs) and recs[cur][0] <= want_fdad:   # CLC 1(8),FDAD / BC 12
            cur += 1
        if cur >= len(recs):
            print("  FAIL: member '%s' not found before EOF (directory TTR desync) -> IEB183I" % name)
            return False
        chunks, term = [], False
        while cur < len(recs):
            _, dl, data = recs[cur]
            cur += 1
            if dl == 0:                            # DL=0 record = end of member (RDEOF)
                term = True
                break
            chunks.append(data)
        if not term:
            print("  FAIL: member '%s' ran off the record stream with no DL=0 EOF -> IEB183I" % name)
            return False
        got = b''.join(chunks)
        want = expect.get(name)                    # None => structural-only (no byte oracle)
        if name not in expect:
            print("  FAIL: unexpected member '%s'" % name)
            ok = False
        elif want is not None and got != want:
            print("  FAIL: member '%s' reload mismatch (%d vs %d bytes)" % (name, len(got), len(want)))
            ok = False

    for name in expect:
        if name not in [n for n, _, _ in entries]:
            print("  FAIL: missing member '%s'" % name)
            ok = False
    if ok and cur != len(recs):
        print("  note: %d trailing record(s) past the last member (no directory entry)"
              % (len(recs) - cur))   # harmless to IEBCOPY (directory-driven), but flag it

    if ok:
        print("  OK: %d member(s) reload (IEBRSAM-faithful), dir sorted, EOF clean" % len(entries))
    return ok


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    expect = {}
    for spec in argv[2:]:
        name, sep, path = spec.partition('=')
        expect[name] = open(path, 'rb').read() if sep else None
    return 0 if check(argv[1], expect) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv))
