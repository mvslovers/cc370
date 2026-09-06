#!/usr/bin/env python3
"""Physical-geometry checker for an ld370 -iebcopy unloaded-PDS image.

WHY THIS EXISTS. ld370 shipped a member layout that was structurally valid,
round-tripped through every host check, and still abended S106-0F (RCIOERR) in
program FETCH on real MVS: emit_unload decided "track full" from BLKSIZE plus a
12-byte unload-record overhead, while a 3350 track holds 19254 bytes with about
185 bytes of gap+count per record.  Tracks claimed 50+ records and up to 24901
bytes on a 19069-byte track -- physically impossible CKD.  mvsMF and BPAM read
such a member anyway, because they are directory-driven and lenient, which is
exactly why the bytes round-tripped and misled the diagnosis; FETCH's channel
program, which positions by each record's on-disk count field, rejected it.

Nothing on the host caught that.  unload_check.py reloads members the way
IEBCOPY does and is therefore just as lenient; the byte-identity oracles compare
ld370 against IEWL captures that predate the bug.  xmit370 has had this check
since it was written (xmit370/tests/xmit_check.py) -- ld370, where the bug
actually happened, did not.  This is that check, for the load-library side.

It is an ABSOLUTE check: every expectation below is a physical property of a
3350 or a fixed field value, never "ld370 agrees with itself".  A wrong shared
constant fails it.

It reads either form: a bare -iebcopy image, or --from-xmit to unwrap the
NETDATA envelope first, so the SAME geometry rules cover both producers of the
unload container -- ld370 for RECFM=U load libraries and xmit370 for RECFM=FB
source libraries.  They share these constants, so they should share the check;
xmit370's own xmit_check.py asserts track density but not the UDEBX extent, and
the extent is what makes a relative TTR resolve to the right absolute track.

usage: track_check.py [--from-xmit] IMAGE... [--data-cc N] [--trkpercyl N]
                      [--template FILE|--no-template] [--recfm U|FB]
"""
import os
import sys

# 3350 physical geometry.  These are properties of the device, not of ld370:
# they must NOT be imported from the tool under test.
TRK_LEN_3350 = 19254        # usable bytes on one 3350 track
TRK_OVH_3350 = 185          # gap + count field per record
MAX_BLK_3350 = TRK_LEN_3350 - TRK_OVH_3350      # 19069: largest single record

ENV_HDR = 328               # COPYR1(52) + COPYR2(276)
COPYR1_LEN = 52             # MVS 3.8j COPYR1 = L$XC138 in DXCOPYR1
COPYR1_EYE = bytes((0xCA, 0x6D, 0x0F))          # at offset 1..3

# COPYR1 / UDEBX field offsets within the env header.
XC1DSORG, XC1BLKSZ, XC1LRECL, XC1RECFM, XC1KEYLN, XC1TBLKS = 4, 6, 8, 10, 11, 14
DEBSTRCC, DEBSTRHH, DEBENDCC, DEBENDHH, DEBNMTRK = 74, 76, 78, 80, 82

# The env header is the echoed COPYR1+COPYR2 template with exactly these fields
# stamped at emit time.  Every OTHER byte must still equal the template -- that
# is what catches a field written to the WRONG OFFSET, which varying the input
# cannot: a wrong offset leaves the right one at its template value, and for a
# field whose correct value never varies (ENDHH is always trk/cyl - 1) the two
# are indistinguishable from the output alone.
# ld370 (load library) touches only the two blocksizes and the extent; xmit370
# (source library) additionally stamps the DCB, because RECV370 allocates the
# target from exactly these fields when the JCL gives no DCB.
STAMPED_EXTENT = ((DEBENDCC, 2), (DEBENDHH, 2), (DEBNMTRK, 2))
STAMPED_LOAD = ((XC1BLKSZ, 2), (XC1TBLKS, 2)) + STAMPED_EXTENT
STAMPED_SRC = ((XC1DSORG, 2), (XC1BLKSZ, 2), (XC1LRECL, 2),
               (XC1RECFM, 1), (XC1KEYLN, 1), (XC1TBLKS, 2)) + STAMPED_EXTENT

DEFAULT_TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                                "fixtures", "unload_env_hdr.bin")

fails = []


def unwrap_xmit(d):
    """NETDATA segments -> (payload, [logical record lengths]).

    Segment = len(1, incl. the 2-byte header) + flags(1) + data; 0x80 first,
    0x40 last, 0x20 control.  Control records are the INMRxx headers and are not
    part of the unloaded image.  The record LENGTHS matter as much as the bytes:
    IEBCOPY writes COPYR1 and COPYR2 as separate logical records, and RECEIVE
    reads them back that way, so a wrong split is a wrong header even when every
    byte is right."""
    out, lens, cur, ctl, p = b"", [], b"", False, 0
    while p + 2 <= len(d):
        ln, flags = d[p], d[p + 1]
        if ln < 2:
            break                      # trailing zero padding in the FB80 block
        if flags & 0x80:
            cur, ctl = b"", bool(flags & 0x20)
        cur += d[p + 2:p + ln]
        if flags & 0x40:
            if not ctl:
                out += cur
                lens.append(len(cur))
            cur = b""
        p += ln
    return (out, lens) if out else (None, [])


def fail(msg):
    fails.append(msg)
    print("  FAIL:", msg)


def be16(b, o):
    return (b[o] << 8) | b[o + 1]


def records(u):
    """Walk the whole record stream: (cc, hh, r, kl, dl, kind)."""
    p, out = ENV_HDR, []
    # directory blocks: count12(KL=8, DL=256) + key(8) + 256
    while p + 12 <= len(u) and u[p + 9] == 8 and be16(u, p + 10) == 256:
        out.append((be16(u, p + 4), be16(u, p + 6), u[p + 8], 8, 256, "dir"))
        p += 12 + 8 + 256
    if u[p:p + 12] != bytes(12):
        fail("end-of-directory marker at %d is not 12 zero bytes" % p)
        return out, p
    p += 12
    while p + 12 <= len(u):
        cc, hh, r = be16(u, p + 4), be16(u, p + 6), u[p + 8]
        kl, dl = u[p + 9], be16(u, p + 10)
        out.append((cc, hh, r, kl, dl, "eof" if dl == 0 else "data"))
        p += 12 + kl + dl
    if p != len(u):
        fail("record stream did not consume to EOF (%d of %d)" % (p, len(u)))
    return out, p


def check(path, data_cc, trkpercyl, template, recfm, from_xmit):
    u = open(path, "rb").read()
    if from_xmit:
        u, lens = unwrap_xmit(u)
        if u is None:
            fail("%s: no unload payload found in the NETDATA envelope" % path)
            return
        # COPYR1 and COPYR2 are separate logical records, and the split is the
        # header: RECEIVE reads them one record at a time, so framing the pair
        # as one record -- or splitting it at the wrong offset -- misreads the
        # DCB even though every byte of the pair is correct.
        if len(lens) < 2:
            fail("%s: payload is %d logical record(s); COPYR1 and COPYR2 must be "
                 "separate" % (path, len(lens)))
        elif lens[0] != COPYR1_LEN or lens[1] != ENV_HDR - COPYR1_LEN:
            fail("%s: env header framed as %d + %d bytes, expected %d + %d "
                 "(COPYR1 + COPYR2)" % (path, lens[0], lens[1], COPYR1_LEN,
                                        ENV_HDR - COPYR1_LEN))
    if len(u) < ENV_HDR:
        fail("%s is shorter than the %d-byte env header" % (path, ENV_HDR))
        return

    # 1. the echoed COPYR1/COPYR2 template is intact where it must be
    if u[1:4] != COPYR1_EYE:
        fail("COPYR1 eyecatcher is %s, expected %s"
             % (u[1:4].hex(' '), COPYR1_EYE.hex(' ')))
    if be16(u, XC1DSORG) != 0x0200:
        fail("COPYR1 DSORG is %04X, expected 0200 (PO)" % be16(u, XC1DSORG))
    if recfm is not None and u[XC1RECFM] != recfm:
        fail("COPYR1 RECFM is %02X, expected %02X" % (u[XC1RECFM], recfm))
    if u[XC1KEYLN] != 0:
        fail("COPYR1 KEYLEN is %d, expected 0" % u[XC1KEYLN])
    blk = be16(u, XC1BLKSZ)
    if be16(u, XC1TBLKS) != blk + 20:
        fail("COPYR1 off %d is %d, expected BLKSIZE+20 = %d"
             % (XC1TBLKS, be16(u, XC1TBLKS), blk + 20))

    # 1b. every byte the emitter does not stamp must still be the template's.
    if template is not None:
        mutable = set()
        for off, n in (STAMPED_LOAD if recfm == 0xC0 else STAMPED_SRC):
            mutable.update(range(off, off + n))
        bad = [i for i in range(ENV_HDR)
               if i not in mutable and u[i] != template[i]]
        if bad:
            runs = []
            for i in bad:
                if runs and i == runs[-1][1] + 1:
                    runs[-1][1] = i
                else:
                    runs.append([i, i])
            fail("env header differs from the template outside the stamped fields "
                 "at %s -- a field written to the wrong offset, or a corrupted "
                 "template" % ", ".join("%d..%d" % (a, b) for a, b in runs))

    recs, _ = records(u)
    if not recs:
        fail("no records found")
        return

    # 2. no single record can exceed what one track physically holds
    for cc, hh, r, kl, dl, kind in recs:   # directory blocks included: they are records too
        if TRK_OVH_3350 + kl + dl > TRK_LEN_3350:
            fail("record CC=%04X HH=%04X R=%d is %d bytes (KL=%d DL=%d), over the "
                 "%d-byte track" % (cc, hh, r, kl + dl, kl, dl, MAX_BLK_3350))

    # Directory records are NOT on the data extent: IEBCOPY writes them with
    # CC=HH=R=0 and the reload finds them by position, not by address.  Check
    # their shape, then leave them out of the geometry below.
    for cc, hh, r, kl, dl, kind in recs:
        if kind == "dir" and (cc, hh, r) != (0, 0, 0):
            fail("directory record has CC=%04X HH=%04X R=%d, expected 0/0/0"
                 % (cc, hh, r))
    geo = [t for t in recs if t[5] != "dir"]
    if not geo:
        fail("no member-data records")
        return

    # 3. THE density assertion -- the one that was missing.  Cost every record at
    #    real 3350 rates and require the track to be able to hold them.  The
    #    DL=0 EOF record counts: it occupies a slot and its gap+count is real.
    tracks = {}
    for cc, hh, r, kl, dl, kind in geo:
        tracks.setdefault((cc, hh), []).append((r, TRK_OVH_3350 + kl + dl))
    for (cc, hh), items in sorted(tracks.items()):
        cost = sum(c for _, c in items)
        if cost > TRK_LEN_3350:
            fail("track CC=%04X HH=%04X holds %d records costing %d bytes, over the "
                 "%d-byte 3350 track" % (cc, hh, len(items), cost, TRK_LEN_3350))

    # 4. record numbers on a track must be 1..n with no gap or repeat -- FETCH
    #    positions by R, so a hole is as fatal as an over-packed track.
    for (cc, hh), items in sorted(tracks.items()):
        rs = sorted(r for r, _ in items)
        if rs != list(range(1, len(rs) + 1)):
            fail("track CC=%04X HH=%04X has R values %s, expected 1..%d"
                 % (cc, hh, rs, len(rs)))

    # 5. the UDEBX data extent must actually SPAN every track written.  This is
    #    what makes the directory's relative TTR resolve to the right absolute
    #    MBBCCHHR; if the extent is short, the reload reads the wrong track.
    strcc, strhh = be16(u, DEBSTRCC), be16(u, DEBSTRHH)
    endcc, endhh = be16(u, DEBENDCC), be16(u, DEBENDHH)
    nmtrk = be16(u, DEBNMTRK)
    if strcc != data_cc:
        fail("UDEBX start CC is %04X, expected %04X" % (strcc, data_cc))
    if strhh != 0:
        fail("UDEBX start HH is %d, expected 0" % strhh)
    if endhh != trkpercyl - 1:
        fail("UDEBX end HH is %d, expected %d (trk/cyl - 1)" % (endhh, trkpercyl - 1))
    ncyl = endcc - strcc + 1
    if nmtrk != ncyl * trkpercyl:
        fail("UDEBX NMTRK is %d, expected %d (%d cyl x %d trk)"
             % (nmtrk, ncyl * trkpercyl, ncyl, trkpercyl))
    for (cc, hh) in sorted(tracks):
        if hh >= trkpercyl:
            fail("track HH=%d is past the %d tracks in a cylinder" % (hh, trkpercyl))
        abs_trk = (cc - strcc) * trkpercyl + hh
        if cc < strcc or cc > endcc or abs_trk >= nmtrk:
            fail("track CC=%04X HH=%04X (relative track %d) is outside the UDEBX "
                 "extent CC %04X..%04X, NMTRK %d" % (cc, hh, abs_trk, strcc, endcc, nmtrk))

    if not fails:
        used = len(tracks)
        worst = max(sum(c for _, c in v) for v in tracks.values())
        print("  OK: %s -- %d data record(s) on %d track(s), fullest %d/%d bytes, "
              "extent CC %04X..%04X NMTRK %d, BLKSIZE %d"
              % (path.rsplit('/', 1)[-1], len(geo), used, worst, TRK_LEN_3350,
                 strcc, endcc, nmtrk, blk))


RECFM = {"U": 0xC0, "F": 0x80, "FB": 0x90}


def main(argv):
    data_cc, trkpercyl, paths = 0x8D, 30, []
    tpath, recfm, from_xmit = DEFAULT_TEMPLATE, 0xC0, False
    i = 1
    while i < len(argv):
        if argv[i] == "--data-cc":
            i += 1; data_cc = int(argv[i], 0)
        elif argv[i] == "--trkpercyl":
            i += 1; trkpercyl = int(argv[i], 0)
        elif argv[i] == "--template":
            i += 1; tpath = argv[i]
        elif argv[i] == "--no-template":
            tpath = None
        elif argv[i] == "--recfm":
            i += 1
            if argv[i] not in RECFM:
                sys.exit("--recfm must be one of %s" % "/".join(RECFM))
            recfm = RECFM[argv[i]]
        elif argv[i] == "--from-xmit":
            from_xmit = True
        else:
            paths.append(argv[i])
        i += 1
    if not paths:
        sys.exit(__doc__)
    template = None
    if tpath and os.path.exists(tpath):
        template = open(tpath, "rb").read()
        if len(template) != ENV_HDR:
            sys.exit("template %s is %d bytes, expected %d" % (tpath, len(template), ENV_HDR))
    elif tpath:
        sys.exit("template %s not found" % tpath)
    for p in paths:
        check(p, data_cc, trkpercyl, template, recfm, from_xmit)
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
