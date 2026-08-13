#!/usr/bin/env python3
"""Structural checker for xmit370-produced XMIT files.

Verifies the things a host byte-diff cannot: that the NETDATA framing obeys the
rules RECV370 depends on, that the blocking matches the declared DCB, and that
the CKD track packing is physically possible on the device the header claims.

usage: xmit_check.py FILE.xmit [--lrecl N] [--blocksize N] [--recfm FB|F]
                               [--members N] [--stats|--no-stats]
"""
import sys

TRK_LEN_3350 = 19254      # physical bytes on a 3350 track
TRK_OVH_3350 = 185        # per-record gap + count overhead
MAX_BLK_3350 = 19069      # = TRK_LEN - TRK_OVH: largest single block on a track

fails = []


def fail(msg):
    fails.append(msg)
    print("  FAIL:", msg)


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def rdval(b):
    v = 0
    for x in b:
        v = (v << 8) | x
    return v


def segments(d):
    """NETDATA segments -> logical records [(is_control, bytes)]."""
    recs, cur, ctl, p = [], b"", False, 0
    while p + 2 <= len(d):
        ln, flags = d[p], d[p + 1]
        if ln < 2:
            break                      # zero padding at end of file
        if flags & 0x80:
            cur, ctl = b"", bool(flags & 0x20)
        cur += d[p + 2:p + ln]
        if flags & 0x40:
            recs.append((ctl, cur))
            cur = b""
        p += ln
    return recs


def textunits(r):
    """Decode one INMRxx control record into {key: [values]}."""
    out, p = {}, 10 if len(r) > 5 and r[5] == 0xF2 else 6
    while p + 6 <= len(r):
        key, cnt = be16(r, p), be16(r, p + 2)
        q, vals = p + 4, []
        for _ in range(cnt):
            if q + 2 > len(r):
                break
            ln = be16(r, q)
            vals.append(r[q + 2:q + 2 + ln])
            q += 2 + ln
        out.setdefault(key, []).extend(vals)
        p = q
    return out


INMDSNAM, INMDIR, INMBLKSZ = 0x0002, 0x000C, 0x0030
INMDSORG, INMLRECL, INMRECFM = 0x003C, 0x0042, 0x0049
INMUTILN, INMSIZE = 0x1028, 0x102C


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    path = args[0]
    want = {"lrecl": 80, "blocksize": 3120, "recfm": "FB",
            "members": None, "stats": True}
    i = 1
    while i < len(args):
        a = args[i]
        if a == "--lrecl":      want["lrecl"] = int(args[i + 1]); i += 2
        elif a == "--blocksize": want["blocksize"] = int(args[i + 1]); i += 2
        elif a == "--recfm":     want["recfm"] = args[i + 1].upper(); i += 2
        elif a == "--members":   want["members"] = int(args[i + 1]); i += 2
        elif a == "--stats":     want["stats"] = True; i += 1
        elif a == "--no-stats":  want["stats"] = False; i += 1
        else:
            print("unknown option", a); return 2

    d = open(path, "rb").read()

    # 1. FB80 envelope
    if len(d) % 80:
        fail("file is %d bytes, not a multiple of 80 (RECFM=FB80)" % len(d))

    recs = segments(d)
    ctl = [r for c, r in recs if c]
    data = [r for c, r in recs if not c]

    # 2. the INMR set a one-file PDS transmission must carry
    seen = [bytes(r[:6]).decode("cp037") for r in ctl]
    for need in ("INMR01", "INMR02", "INMR03", "INMR06"):
        if need not in seen:
            fail("missing control record %s (have %s)" % (need, seen))
    if seen.count("INMR02") != 2:
        fail("expected 2 INMR02 records (IEBCOPY + INMCOPY), got %d" % seen.count("INMR02"))

    # 3. INMR02 #1 must describe the source library exactly as asked for
    tu1 = None
    for r in ctl:
        if bytes(r[:6]).decode("cp037") == "INMR02":
            t = textunits(r)
            if t.get(INMUTILN) and t[INMUTILN][0].decode("cp037").strip() == "IEBCOPY":
                tu1 = t
                break
    if tu1 is None:
        fail("no IEBCOPY INMR02 record")
    else:
        recfm_bits = rdval(tu1[INMRECFM][0]) >> 8
        got = ("U" if recfm_bits & 0xC0 == 0xC0 else "F" if recfm_bits & 0x80 else "V")
        if recfm_bits & 0x10:
            got += "B"
        if got != want["recfm"]:
            fail("INMR02#1 RECFM is %s, expected %s" % (got, want["recfm"]))
        if rdval(tu1[INMLRECL][0]) != want["lrecl"]:
            fail("INMR02#1 LRECL is %d, expected %d" % (rdval(tu1[INMLRECL][0]), want["lrecl"]))
        if rdval(tu1[INMBLKSZ][0]) != want["blocksize"]:
            fail("INMR02#1 BLKSIZE is %d, expected %d" % (rdval(tu1[INMBLKSZ][0]), want["blocksize"]))
        if rdval(tu1[INMDSORG][0]) != 0x0200:
            fail("INMR02#1 DSORG is not PO")

    # 4. payload = the unloaded image
    u = b"".join(data)
    c1 = data[0] if data else b""
    if len(c1) < 16 or c1[1:4] != b"\xca\x6d\x0f":
        fail("first data record is not COPYR1")
        return 1 if fails else 0
    hdrlen = len(data[0]) + len(data[1])

    if be16(u, 4) != 0x0200:
        fail("COPYR1 DSORG is not PO")
    if be16(u, 6) != want["blocksize"]:
        fail("COPYR1 BLKSIZE (off 6) is %d, expected %d" % (be16(u, 6), want["blocksize"]))
    if be16(u, 8) != want["lrecl"]:
        fail("COPYR1 LRECL (off 8) is %d, expected %d" % (be16(u, 8), want["lrecl"]))
    want_rf = 0x90 if want["recfm"] == "FB" else 0x80
    if u[10] != want_rf:
        fail("COPYR1 RECFM (off 10) is %02X, expected %02X" % (u[10], want_rf))
    if be16(u, 14) != want["blocksize"] + 20:
        fail("COPYR1 unloaded BLKSIZE (off 14) is %d, expected %d"
             % (be16(u, 14), want["blocksize"] + 20))

    # 5. directory: entry size must agree with the C byte
    entsz = 12 + (30 if want["stats"] else 0)
    cbyte = 0x0F if want["stats"] else 0x00
    p, nent, ndb = hdrlen, 0, 0
    while p + 12 <= len(u) and u[p + 9] == 8 and be16(u, p + 10) == 256:
        ndb += 1
        blk = u[p + 20:p + 20 + 256]
        used, o = be16(blk, 0), 2
        if used > 256:
            fail("directory block %d claims used=%d" % (ndb, used))
        while o + 12 <= used:
            if blk[o:o + 8] == b"\xff" * 8:
                break
            if blk[o + 11] != cbyte:
                fail("member %r C byte is %02X, expected %02X"
                     % (bytes(blk[o:o + 8]).decode("cp037"), blk[o + 11], cbyte))
            nent += 1
            o += 12 + (blk[o + 11] & 0x1F) * 2
        p += 12 + 8 + 256
    while p + 12 <= len(u) and u[p + 9] == 0 and be16(u, p + 10) == 0 and u[p + 4:p + 9] == b"\0" * 5:
        p += 12
    data_off = p
    if want["members"] is not None and nent != want["members"]:
        fail("directory holds %d members, expected %d" % (nent, want["members"]))
    if entsz != 12 + (cbyte & 0x1F) * 2:
        fail("internal: entry size mismatch")

    # 6. member data: block sizes and the per-member EOF, plus track packing
    tracks = {}
    p = data_off
    nblk = 0
    while p + 12 <= len(u):
        cc, hh, r = be16(u, p + 4), be16(u, p + 6), u[p + 8]
        kl, dl = u[p + 9], be16(u, p + 10)
        if dl:
            if dl > want["blocksize"]:
                fail("block at CC=%04X HH=%04X R=%d is %d bytes > BLKSIZE %d"
                     % (cc, hh, r, dl, want["blocksize"]))
            if dl % want["lrecl"]:
                fail("block at CC=%04X HH=%04X R=%d is %d bytes, not a multiple of LRECL %d"
                     % (cc, hh, r, dl, want["lrecl"]))
            nblk += 1
        if dl > MAX_BLK_3350:
            fail("block at CC=%04X HH=%04X R=%d is %d bytes, over the %d-byte device maximum"
                 % (cc, hh, r, dl, MAX_BLK_3350))
        tracks.setdefault((cc, hh), []).append(TRK_OVH_3350 + dl)
        p += 12 + kl + dl

    # THE density assertion: a track must be physically able to hold what we
    # claim sits on it.  Over-packing produced a valid-looking image that
    # program FETCH rejected with S106-0F; costing by BLKSIZE hides it.
    for (cc, hh), costs in sorted(tracks.items()):
        if sum(costs) > TRK_LEN_3350:
            fail("track CC=%04X HH=%04X holds %d records costing %d bytes, over the %d-byte track"
                 % (cc, hh, len(costs), sum(costs), TRK_LEN_3350))

    # 7. per-member VS framing: no record may follow a DL=0 inside one logical
    # record.  IEBCOPY LOAD reads SYSUT1 one VS record at a time and loses
    # anything packed behind an end-of-member -> IEB183I.
    off = 0
    for rec in data:
        q = 0
        if off < hdrlen:            # COPYR1 / COPYR2 are not count-prefixed
            off += len(rec)
            continue
        while q + 12 <= len(rec):
            dl = be16(rec, q + 10)
            q += 12 + rec[q + 9] + dl
            if dl == 0 and q < len(rec):
                fail("a logical record continues past a DL=0 end-of-member "
                     "(RECV370 would lose the following member: IEB183I)")
                break
        off += len(rec)

    print("OK: %s -- FB80, %d member(s), %d directory block(s), %d block(s), "
          "%d track(s), RECFM=%s LRECL=%d BLKSIZE=%d"
          % (path, nent, ndb, nblk, len(tracks), want["recfm"], want["lrecl"],
             want["blocksize"]) if not fails else "FAILED: %d check(s)" % len(fails))
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
