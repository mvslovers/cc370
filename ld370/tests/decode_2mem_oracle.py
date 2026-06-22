#!/usr/bin/env python3
"""Decode the real 2-member IEBCOPY UNLOAD oracle (e2e2.iebcopy-unload.bin).

Answers the four questions that discriminate the member-boundary layout:
  1. each member's directory TTR  (track + R byte) and PDS2TTRT
  2. the full (CC,HH,R,KL,DL) ladder of every data + EOF record
  3. do the two members SHARE a track (continuous R) or start fresh tracks?
  4. where does each DL=0 EOF sit -- its own record at R+1 on the member's last
     data track, or alone on its own track?

The oracle's MBBCCHHR are ABSOLUTE disk addresses (wherever IEWL placed the
library); only the RELATIVE structure (R-continuity, track sharing, EOF
placement) carries over to ld370's echoed-geometry layout -- that's what we read.
"""
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT = os.path.join(REPO, "ld370", "tests", "fixtures", "e2e2.iebcopy-unload.bin")


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def e2a(e):
    t = {0xC1 + i: chr(ord('A') + i) for i in range(9)}
    t.update({0xD1 + i: chr(ord('J') + i) for i in range(9)})
    t.update({0xE2 + i: chr(ord('S') + i) for i in range(8)})
    t.update({0xF0 + i: chr(ord('0') + i) for i in range(10)})
    t[0x40] = ' '
    return t.get(e, '.')


def mbbcchhr(key):
    """key = M BB CC HH R (8 bytes) -> (cc, hh, r)."""
    return be16(key, 3), be16(key, 5), key[7]


def find_dir(u):
    """Locate the directory record: first count12 with KL=8, DL=256."""
    for p in range(0, len(u) - 12):
        if u[p] == 0 and u[p + 9] == 8 and be16(u, p + 10) == 256:
            return p
    raise SystemExit("no directory record (KL=8 DL=256) found")


def main(argv):
    path = argv[1] if len(argv) > 1 else DEFAULT
    u = open(path, 'rb').read()
    print(f"oracle {path}: {len(u)} bytes\n")

    # --- env header / COPYR1 geometry ---------------------------------------
    eye = bytes([0xCA, 0x6D, 0x0F])
    c1 = u.find(eye) - 1
    print(f"COPYR1 @ {c1}: UDSORG={u[c1+4]:02x}{u[c1+5]:02x} "
          f"UBLKSIZE={be16(u, c1+6)} URECFM={u[c1+10]:02x} "
          f"UDEVTYPE={u[c1+16:c1+24].hex()}")

    dirp = find_dir(u)
    print(f"env header length (bytes before directory record) = {dirp}\n")

    # --- directory block: members + TTRs + user-data (PDS2) -----------------
    block = u[dirp + 20:dirp + 20 + 256]
    used = be16(block, 0)
    print(f"directory block: used={used} bytes")
    q = 2
    members = []
    while q < used and block[q] != 0xFF:
        name = ''.join(e2a(c) for c in block[q:q + 8]).rstrip()
        tt = be16(block, q + 8)
        r = block[q + 10]
        cbyte = block[q + 11]
        nhw = cbyte & 0x1F
        ud = block[q + 12:q + 12 + nhw * 2]
        pds2ttrt = (be16(ud, 0), ud[2]) if len(ud) >= 3 else None
        members.append((name, tt, r))
        print(f"  {name:<8} dir-TTR=(TT={tt},R={r})  C=0x{cbyte:02x} "
              f"({nhw} halfwords userdata)  PDS2TTRT={pds2ttrt}  ud={ud.hex()}")
        q += 12 + nhw * 2
    print()

    # --- walk every count12 record after the directory ----------------------
    p = dirp + 12 + 8 + 256
    print("record ladder (after directory):")
    print("  idx  CC   HH   R   KL    DL   note")
    idx = 0
    while p + 12 <= len(u):
        f = u[p]
        cc, hh, r = mbbcchhr(u[p + 1:p + 9])
        kl, dl = u[p + 9], be16(u, p + 10)
        note = ""
        if f == 0 and cc == 0 and hh == 0 and r == 0 and kl == 0 and dl == 0:
            note = "<-- end-of-directory marker" if idx == 0 else "<-- DL=0 EOF"
        elif dl == 0:
            note = "<-- DL=0 EOF (end of member)"
        print(f"  {idx:>3}  {cc:#06x} {hh:#04x} {r:>3}  {kl:>2}  {dl:>5}   {note}")
        p += 12 + kl + dl
        idx += 1
    if p != len(u):
        print(f"  (stream not fully consumed: {p} of {len(u)})")


if __name__ == "__main__":
    main(sys.argv)
