#!/bin/sh
# ld370 regression: build the toolchain, link each case with the host-native
# chain (as370 per source -> ld370 over all the objects), and byte-diff the
# result against the IEWL oracle via the record-aware differ. Non-zero on any
# mismatch.
#
# The diff is carve-out-aware: the IDR identity records (LKED/translator)
# legitimately differ (ld stamps its own identity) and are skipped; the
# byte-exact target is CESD + SPZAP-IDR + control + text + RLD.
cd "$(dirname "$0")/../.." || exit 2          # repo root (cc370)

AS=./as370/as370
LD=./ld370/ld370
AR=./ar370/ar370
DIFF="python3 ld370/tests/lmdiff.py"
FIX=ld370/tests/fixtures
TMP="${TMPDIR:-/tmp}"

[ -x "$AS" ] || gcc -O2 -Wall -Wextra -Werror -Ias370/include -o "$AS" as370/src/as370.c || exit 2
gcc -O2 -Wall -Wextra -Werror -o "$LD" ld370/src/ld370.c || exit 2
gcc -O2 -Wall -Wextra -Werror -o "$AR" ar370/src/ar370.c || exit 2

fails=0

# run_case NAME ORACLE.bin SRC1.s [SRC2.s ...]
#   assemble each source with as370, link all objects with ld370, diff vs oracle
run_case() {
    name=$1; oracle=$2; shift 2
    objs=""
    for s in "$@"; do
        "$AS" -o "$TMP/$name.$s.obj" "$FIX/$s" || { echo "as370 failed: $s"; fails=$((fails + 1)); return; }
        objs="$objs $TMP/$name.$s.obj"
    done
    # --allow-unresolved: these fixtures byte-match IEWL NCAL output, which
    # deliberately leaves ERs unresolved (e.g. rldt's V(EXTRTN)).
    # shellcheck disable=SC2086
    "$LD" -o "$TMP/$name.ld.bin" -iebcopy --name "$name" --allow-unresolved $objs \
        || { echo "ld370 failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== %s  (oracle %s) ===\n' "$name" "$oracle"
    $DIFF diff "$FIX/$oracle" "$TMP/$name.ld.bin" || fails=$((fails + 1))
    # round-trip: the -iebcopy image must reconstruct the member just linked.
    # Guards split_member on the control/RLD path real modules take (e2e is
    # RLD-free, so this is the only host-side check of the 0x0E branch).
    NM=$(printf '%s' "$name" | tr 'a-z' 'A-Z')   # member_name() upper-cases
    python3 ld370/tests/unload_check.py "$TMP/$name.ld.bin.iebcopy" "$NM=$TMP/$name.ld.bin" \
        || fails=$((fails + 1))
}

run_case tiny  tiny1.bin tiny.s
run_case rldt  rldt.bin  rldt.s
run_case modab  modab.bin  mod_a.s mod_b.s
run_case twosec twosec.bin twosec.s     # two distinct CSECTs in one object
run_case klein  klein.bin  klein.s      # ENTRY/LD (-> composite LR) + RLD SAMERP continuation

# IEBCOPY unloaded-image emitter: wrap a known IEWL member and structurally
# check that it reconstructs from the device-agnostic one-block-per-track image.
# Byte-identity to a real IEBCOPY UNLOAD no longer applies -- we deliberately
# under-pack (one block per track) so the image loads on ANY target DASD.  The
# real oracle is RECV370 LOAD + run on MVS: validated 2026-06-20, the e2e member
# installs (IEB154I) and runs (RC=7) through the multi-track emitter.
run_unload() {
    name=$1; member=$2; mname=$3
    "$LD" --pack "$mname=$FIX/$member" -o "$TMP/$name" -iebcopy \
        || { echo "ld370 -iebcopy failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== unload %s ===\n' "$name"
    python3 ld370/tests/unload_check.py "$TMP/$name.iebcopy" "$mname=$FIX/$member" \
        || fails=$((fails + 1))
}

run_unload e2e e2e.iewl-member.bin E2E

# XMIT (TSO TRANSMIT / NETDATA) wrapper: wrap the e2e member's unload and check
# FB80 + the INMR control set + that the data records carry the unload payload
# byte-faithfully.  Validated end-to-end on MVS: the FB80 upload RECV370-installs
# (IEB154I) and the member runs (RC=7) through the multi-track emitter.
printf '\n=== xmit e2e ===\n'
if "$LD" --pack "E2E=$FIX/e2e.iewl-member.bin" --dsn IBMUSER.E2E.LOAD \
        -o "$TMP/e2e" -iebcopy -xmit 2>/dev/null; then
    python3 ld370/tests/xmit_check.py "$TMP/e2e.xmit" "$TMP/e2e.iebcopy" \
        || fails=$((fails + 1))
else
    echo "ld370 -xmit failed"; fails=$((fails + 1))
fi

# multi-member: pack linked members into one library image (deliberately in
# non-sorted input order) and confirm every member RELOADS via the faithful
# IEBRSAM simulator (per-member DL=0 EOF + directory-driven find), with the
# directory name-sorted.  No byte oracle -- the MVS RECV370 round-trip is the
# arbiter; the simulator is its host-side stand-in (it fails the old single-EOM
# layout, so a green here is meaningful, not a slice-back-out tautology).
printf '\n=== pack tiny+rldt (multi-member) ===\n'
if "$LD" --pack "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" \
        -o "$TMP/lib2" -iebcopy 2>/dev/null; then
    python3 ld370/tests/unload_check.py "$TMP/lib2.iebcopy" \
        "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" || fails=$((fails + 1))
else
    echo "ld370 --pack failed"; fails=$((fails + 1))
fi

# 3 members: exercises a MIDDLE member (found after a prior member's EOF and
# itself followed by another) -- the position a 2-member pack cannot reach.
printf '\n=== pack tiny+rldt+klein (3 members) ===\n'
if "$LD" --pack "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" "KLEIN=$TMP/klein.ld.bin" \
        -o "$TMP/lib3" -iebcopy 2>/dev/null; then
    python3 ld370/tests/unload_check.py "$TMP/lib3.iebcopy" \
        "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" "KLEIN=$TMP/klein.ld.bin" || fails=$((fails + 1))
else
    echo "ld370 --pack (3) failed"; fails=$((fails + 1))
fi

# POSITIVE CONTROL: the simulator must reconstruct a REAL 2-member IEBCOPY UNLOAD
# (captured from MVS by run_2mem_oracle.py: IEWL 2 members -> IEBCOPY UNLOAD).
# The earlier simulator had only a negative control, so it confidently accepted a
# layout MVS rejected.  Reading the geometry from the header lets the same check
# validate this real oracle (start CC 0x178) -- if it can't reload the layout
# IEBCOPY itself writes, it cannot be trusted to bless ld370's.
printf '\n=== oracle: real 2-member IEBCOPY UNLOAD reloads (positive control) ===\n'
if [ -f "$FIX/e2e2.iebcopy-unload.bin" ]; then
    python3 ld370/tests/unload_check.py "$FIX/e2e2.iebcopy-unload.bin" E2EA E2EB \
        || fails=$((fails + 1))
else
    echo "  SKIP: $FIX/e2e2.iebcopy-unload.bin missing (run run_2mem_oracle.py)"
fi

# SIM SANITY (negative): a single-EOM image (member 1 runs into member 2) MUST be
# rejected -- otherwise a green above is a slice-back-out tautology.  NB this is
# NOT the layout that abended on MVS; that was an XMIT transport bug (below), which
# this unload-image simulator structurally cannot see.
printf '\n=== sim sanity: single-EOM layout is rejected ===\n'
python3 ld370/tests/strip_interior_eof.py "$TMP/lib2.iebcopy" "$TMP/lib2_seom.iebcopy"
if python3 ld370/tests/unload_check.py "$TMP/lib2_seom.iebcopy" \
        "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" >/dev/null 2>&1; then
    echo "  FAIL: simulator accepted the single-EOM layout (no teeth)"; fails=$((fails + 1))
else
    echo "  OK: simulator rejected the single-EOM layout (has teeth)"
fi

# TRANSPORT GUARD: the multi-member XMIT must frame each member in its OWN VS
# logical record.  IEBCOPY LOAD reads SYSUT1 one VS record at a time, so a later
# member packed behind an earlier member's DL=0 EOF in one record is lost on
# reload (IEB183I) -- the ACTUAL cause of every failed 2-member round-trip,
# invisible to the unload-image sim.  Validated on MVS 2026-06-22: per-member
# framing installs both members (IEB154I x2) and each runs (RUNA=0007, RUNB=0003).
printf '\n=== multi-member XMIT per-member VS framing (transport guard) ===\n'
if "$LD" --pack "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" \
        --dsn IBMUSER.LIB2.LOAD -o "$TMP/lib2x" -iebcopy -xmit 2>/dev/null; then
    python3 ld370/tests/xmit_check.py "$TMP/lib2x.xmit" "$TMP/lib2x.iebcopy" \
        || fails=$((fails + 1))
else
    echo "ld370 -xmit (multi-member) failed"; fails=$((fails + 1))
fi

# --pack PDS2 directory: a bare .lm carries NO directory metadata (entry point,
# module length, AC, RENT/REUS/... are all attributes IEWL writes only to the
# directory).  --pack used to template these -> SIZE 8 / entry 0 / AC 0 for every
# packed member.  Packing a single-member -iebcopy (self-describing) now copies
# the WHOLE PDS2 user-data and only re-stamps PDS2TTRT, so the result is
# byte-identical to the single link that produced it.  nzent has a NON-ZERO entry
# (GO at offset 16) and is linked --ac 1, guarding entry + modlen + AC together.
printf '\n=== --pack -iebcopy round-trips PDS2 dir (entry+modlen+AC, byte-identical) ===\n'
"$AS" -o "$TMP/nzent.o" "$FIX/nzent.s" 2>/dev/null
"$LD" --ac 1 -o "$TMP/nzent_lnk" --name NZENT "$TMP/nzent.o" -iebcopy 2>/dev/null
"$LD" --pack "NZENT=$TMP/nzent_lnk.iebcopy" -o "$TMP/nzent_pak" -iebcopy 2>/dev/null
if cmp -s "$TMP/nzent_lnk.iebcopy" "$TMP/nzent_pak.iebcopy"; then
    echo "  OK: pack-from-iebcopy == single-link directory (entry 0x10 + modlen + AC 1)"
else
    echo "  FAIL: pack-from-iebcopy directory differs from single-link"; fails=$((fails + 1))
fi

# large-RLD object keeps its exported LD symbols.  parse_object used fixed
# rld[512]/ld[64] arrays with no bounds check; an object with >512 RLD items
# (large C cores -- rexx370's irx#pars/bcom/bifs/bvm) overflowed rld[] into the
# adjacent ld[] (RLD cards follow ESD cards, so LD entries were recorded then
# CLOBBERED), so a cross-object reference to such a symbol came back "unresolved"
# -- the rexx370 mbt-v2 link failure.  600 A-cons -> >512 RLD items; GO (an LD in
# that object) must still resolve from a second object.  Linked WITHOUT
# --allow-unresolved, so an unresolved GO fails the link (non-zero exit).
printf '\n=== large-RLD object keeps its LD symbols (>512 RLD, no overflow) ===\n'
{ echo "BIGRLD   CSECT"; echo "         ENTRY GO"; echo "GO       BR    14"
  awk 'BEGIN{for(i=0;i<600;i++)print "         DC    A(GO)"}'; echo "         END"; } > "$TMP/bigrld.s"
printf 'REF      CSECT\n         DC    V(GO)\n         BR    14\n         END   REF\n' > "$TMP/ref.s"
if "$AS" -o "$TMP/bigrld.o" "$TMP/bigrld.s" 2>/dev/null \
   && "$AS" -o "$TMP/ref.o" "$TMP/ref.s" 2>/dev/null \
   && "$LD" -e REF "$TMP/ref.o" "$TMP/bigrld.o" -iebcopy -o "$TMP/bigrld_link" 2>/dev/null; then
    echo "  OK: GO (LD in a >512-RLD object) resolved across objects"
else
    echo "  FAIL: GO unresolved -- rld[]/ld[] overflow regressed"; fails=$((fails + 1))
fi

# multi-block PDS directory: >6 members spill into multiple 256-byte directory
# blocks.  The directory was a single fixed dir[256] that overflowed at the 7th
# member (>6 entries + the FF terminator) -> SIGABRT; rexx370 packs 12.  Pack 7
# and 20 members; the result must not crash and every member must reload (the sim
# walks all directory blocks, 7 entries per non-last block + FF terminator block).
printf '\n=== multi-block directory (>6 members, no dir[256] overflow) ===\n'
mb_fails=0
for cnt in 7 20; do
    specs=""; names=""; i=1
    while [ "$i" -le "$cnt" ]; do
        m=$(printf 'MOD%02d' "$i")
        printf '%-8s CSECT\n         BR    14\n         END   %s\n' "$m" "$m" > "$TMP/$m.s"
        "$AS" -o "$TMP/$m.o" "$TMP/$m.s" 2>/dev/null
        "$LD" -o "$TMP/$m.lm" --name "$m" "$TMP/$m.o" 2>/dev/null
        specs="$specs $m=$TMP/$m.lm"; names="$names $m"
        i=$((i + 1))
    done
    # shellcheck disable=SC2086
    if "$LD" --pack $specs -o "$TMP/lib$cnt" -iebcopy 2>/dev/null \
       && python3 ld370/tests/unload_check.py "$TMP/lib$cnt.iebcopy" $names >/dev/null 2>&1; then
        echo "  OK: $cnt members -> multi-block directory, all reload"
    else
        echo "  FAIL: $cnt-member pack crashed or a member did not reload"; mb_fails=1
    fi
done
[ "$mb_fails" -eq 0 ] || fails=$((fails + 1))

# grow-on-demand whole-link tables: O[] (objects), G[] (composite symbols), the
# archive symbol index and the pulled-member list all grow now (were fixed
# O[1024]/G[8192]/sym[16384]; the silent ones could DROP symbols).  These tests
# cross the 256-element initial-capacity boundary (forcing reallocs) and require
# a HIGH-index symbol/object to still resolve -- so a corrupting or truncating
# grow fails the link, not just a count over the old cap.
printf '\n=== grow: archive symbol index + composite G[] (300 sections) ===\n'
awk 'BEGIN{for(i=1;i<=300;i++)printf "C%03d     CSECT\n         BR    14\n",i; print "         END"}' > "$TMP/big.s"
printf 'GROOT    CSECT\n         DC    V(C290)\n         BR    14\n         END   GROOT\n' > "$TMP/groot.s"
if "$AS" -o "$TMP/big.o" "$TMP/big.s" 2>/dev/null && "$AS" -o "$TMP/groot.o" "$TMP/groot.s" 2>/dev/null \
   && "$AR" rc "$TMP/big.a" "$TMP/big.o" 2>/dev/null \
   && "$LD" -e GROOT "$TMP/groot.o" "$TMP/big.a" -iebcopy -o "$TMP/gbig" 2>/dev/null; then
    echo "  OK: C290 (past the 256 grow boundary) resolved via the archive index"
else
    echo "  FAIL: high symbol unresolved -- archive index / G[] grow regressed"; fails=$((fails + 1))
fi

printf '\n=== grow: object array O[] (300 loose objects, &O[i] across realloc) ===\n'
g_specs=""; i=0
while [ "$i" -lt 300 ]; do
    s=$(printf 'S%03d' "$i")
    if [ "$i" -eq 0 ]; then ref="         DC    V(S299)\n"; else ref=""; fi
    printf "%-8s CSECT\n${ref}         BR    14\n         END\n" "$s" > "$TMP/$s.s"
    "$AS" -o "$TMP/$s.o" "$TMP/$s.s" 2>/dev/null
    g_specs="$g_specs $TMP/$s.o"
    i=$((i + 1))
done
# shellcheck disable=SC2086
if "$LD" -e S000 $g_specs -iebcopy -o "$TMP/gobjs" 2>/dev/null; then
    echo "  OK: 300 objects linked; S000->S299 (object 299, past 256) resolved"
else
    echo "  FAIL: O[] grow / &O[i] aliasing across realloc regressed"; fails=$((fails + 1))
fi

printf '\n=== grow: archive member index (--include a member past 256) ===\n'
printf 'IROOT    CSECT\n         BR    14\n         END   IROOT\n' > "$TMP/iroot.s"
"$AS" -o "$TMP/iroot.o" "$TMP/iroot.s" 2>/dev/null
# shellcheck disable=SC2086
if "$AR" rc "$TMP/g300.a" $g_specs 2>/dev/null \
   && "$LD" -e IROOT "$TMP/iroot.o" "$TMP/g300.a" --include S290 -iebcopy -o "$TMP/ginc" 2>/dev/null; then
    echo "  OK: --include S290 (archive member past 256) found -> mem[] index grew"
else
    echo "  FAIL: archive member index (mem[]) grow regressed"; fails=$((fails + 1))
fi

# automatic library call: a member pulled from an ar370 archive must yield the
# SAME module as linking it explicitly (same appearance order => same ESDIDs).
#   modab  = single pull   (mod_a references MODB, in libmodb.a)
#   chain  = transitive    (chain_r->chain_a->chain_b; chain_b is pulled ONLY
#                           because the pulled chain_a references it)
# run_autocall LIBNAME ROOT MEMBER...
run_autocall() {
    name=$1; root=$2; shift 2
    members=""
    "$AS" -o "$TMP/$root.o" "$FIX/$root.s" || { echo "as370 failed: $root"; fails=$((fails + 1)); return; }
    for m in "$@"; do
        "$AS" -o "$TMP/$m.o" "$FIX/$m.s" || { echo "as370 failed: $m"; fails=$((fails + 1)); return; }
        members="$members $TMP/$m.o"
    done
    # shellcheck disable=SC2086
    "$AR" rc "$TMP/lib$name.a" $members || { echo "ar370 failed: $name"; fails=$((fails + 1)); return; }
    # shellcheck disable=SC2086
    "$LD" -o "$TMP/$name.exp" "$TMP/$root.o" $members \
        || { echo "ld370 explicit failed: $name"; fails=$((fails + 1)); return; }
    "$LD" -o "$TMP/$name.auto" -L"$TMP" -l"$name" "$TMP/$root.o" \
        || { echo "ld370 autocall failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== autocall %s ===\n' "$name"
    if cmp -s "$TMP/$name.exp" "$TMP/$name.auto"; then
        echo "autocall == explicit link"
    else
        echo "autocall DIFFERS from explicit"; fails=$((fails + 1))
    fi
}

run_autocall modab mod_a   mod_b
run_autocall chain chain_r chain_a chain_b

# conflict-aware autocall + --include (the @@CRT0/@@EXITA/@@crtm case in
# miniature): the archive has a standalone definer for each wanted symbol
# (cft0=CFT0, cfex=CFEX) AND a "bundle" member (cfdup) that re-defines BOTH.
# cfdup is placed BEFORE cfex so it is the FIRST index entry for CFEX -- a naive
# first-definer autocall would pull it and drag a DUPLICATE CFT0 into the link.
# Conflict-aware autocall must instead skip cfdup (it re-defines the
# already-resolved CFT0) and pull the standalone cfex => identical to explicitly
# linking {cfmain,cft0,cfex}.  --include CFDUP then forces the bundle and leaves
# autocall nothing to pull => identical to explicitly linking {cfmain,cfdup}.
run_conflict() {
    for m in cfmain cft0 cfex cfdup; do
        "$AS" -o "$TMP/$m.o" "$FIX/$m.s" || { echo "as370 failed: $m"; fails=$((fails + 1)); return; }
    done
    "$AR" rc "$TMP/libcf.a" "$TMP/cft0.o" "$TMP/cfdup.o" "$TMP/cfex.o" \
        || { echo "ar370 failed: cf"; fails=$((fails + 1)); return; }
    printf '\n=== autocall conflict (skip the duplicate-defining bundle) ===\n'
    "$LD" -o "$TMP/cf.auto" -L"$TMP" -lcf "$TMP/cfmain.o" \
        || { echo "ld370 autocall failed: cf"; fails=$((fails + 1)); return; }
    "$LD" -o "$TMP/cf.exp" "$TMP/cfmain.o" "$TMP/cft0.o" "$TMP/cfex.o" \
        || { echo "ld370 explicit failed: cf"; fails=$((fails + 1)); return; }
    if cmp -s "$TMP/cf.auto" "$TMP/cf.exp"; then
        echo "autocall skipped the conflicting bundle (== explicit cft0+cfex)"
    else
        echo "autocall pulled the conflicting bundle"; fails=$((fails + 1))
    fi
    printf '\n=== include forces the bundle (--include CFDUP) ===\n'
    "$LD" -o "$TMP/cf.inc" -L"$TMP" -lcf --include CFDUP "$TMP/cfmain.o" \
        || { echo "ld370 include failed: cf"; fails=$((fails + 1)); return; }
    "$LD" -o "$TMP/cf.incexp" "$TMP/cfmain.o" "$TMP/cfdup.o" \
        || { echo "ld370 explicit failed: cf-inc"; fails=$((fails + 1)); return; }
    if cmp -s "$TMP/cf.inc" "$TMP/cf.incexp"; then
        echo "include forced the bundle (== explicit cfdup; autocall pulled nothing)"
    else
        echo "include did not force the bundle"; fails=$((fails + 1))
    fi
}

run_conflict

# --blocksize: the target library BLKSIZE is runtime (default 15040, the de-facto
# LINKLIB blocksize, so a member fits ANY LINKLIB with BLKSIZE >= 15040 -- where the
# old fixed 19069 fit only a fresh >=19069 lib).  A module built at --blocksize B must
# (a) split its text into blocks <= B and (b) stamp COPYR1 off6 = B (library BLKSIZE
# == INMR02#1 INMBLKSZ) and off14 = B+20 (unloaded-PS BLKSIZE == INMR02#2 INMBLKSZ),
# the field mapping confirmed against real oracles (e2e 3350/19069, CBT 3380/6144).
# The XMIT's INMR02#1 INMBLKSZ must match COPYR1 off6.  A 32 KB-text module forces
# the intra-section split so the block ceiling is actually exercised.
printf '\n=== --blocksize: COPYR1 + block sizing + INMR02 (default 15040 + override) ===\n'
{ echo "BIGTXT   CSECT"; echo "         DC    8000F'0'"; echo "GO       BR    14"; echo "         END   GO"; } > "$TMP/bigtxt.s"
"$AS" -o "$TMP/bigtxt.o" "$TMP/bigtxt.s" 2>/dev/null
blk_probe() {  # $1 = ld370 blocksize args (may be empty), $2 = expected BLKSIZE
    # shellcheck disable=SC2086
    "$LD" $1 -o "$TMP/bt" --name BIGTXT "$TMP/bigtxt.o" -iebcopy -xmit 2>/dev/null
    python3 - "$TMP/bt.iebcopy" "$TMP/bt.xmit" "$2" <<'PY'
import sys
u=open(sys.argv[1],'rb').read(); x=open(sys.argv[2],'rb').read(); B=int(sys.argv[3])
def be16(b,o): return (b[o]<<8)|b[o+1]
off6, off14 = be16(u,6), be16(u,14)               # COPYR1 library / PS blocksize
p=328                                             # walk member-data blocks, max DL
while p+12<=len(u) and u[p+9]==8 and be16(u,p+10)==256: p+=12+8+256
p+=12
mx=0
while p+12<=len(u):
    dl=be16(u,p+10); mx=max(mx,dl); p+=12+u[p+9]+dl
# INMR02#1 INMBLKSZ (text unit 0x0030) from the XMIT NETDATA stream
def reassemble(z):
    out,q,cur,ctl=[],0,b'',False
    while q+2<=len(z):
        sl,fl=z[q],z[q+1]
        if sl<2: q+=1; continue
        cur+=z[q+2:q+sl]
        if fl&0x20: ctl=True
        q+=sl
        if fl&0x40: out.append((ctl,cur)); cur,ctl=b'',False
    return out
def tu(rec,key):
    q=10
    while q+4<=len(rec):
        k,num=be16(rec,q),be16(rec,q+2); q+=4; vl=be16(rec,q)
        if k==key:
            v=0
            for j in range(vl): v=(v<<8)|rec[q+2+j]
            return v
        t=q
        for _ in range(num or 1):
            if t+2>len(rec): break
            t+=2+be16(rec,t)
        q=t
    return None
inmr02=[r for c,r in reassemble(x) if c and r[:6]==bytes([0xc9,0xd5,0xd4,0xd9,0xf0,0xf2])]
inmblk=tu(inmr02[0],0x0030) if inmr02 else None
ok = off6==B and off14==B+20 and mx<=B and inmblk==B
print(f"  BLKSIZE={B}: off6={off6} off14={off14}(exp {B+20}) maxblock={mx}(<= {B}) "
      f"INMR02#1.BLKSZ={inmblk} -> {'OK' if ok else 'FAIL'}")
sys.exit(0 if ok else 1)
PY
}
blk_probe "" 15040 || fails=$((fails + 1))                 # default
blk_probe "--blocksize 19069" 19069 || fails=$((fails + 1)) # old default; maxtext 18432
blk_probe "--blocksize 6144" 6144 || fails=$((fails + 1))   # table entry; block may == B

# pack-time guard: --pack reads members as-is (split_member reproduces build-time
# block sizes, it does NOT re-chunk by maxtext), so packing a member built at a
# LARGER --blocksize while declaring a smaller one would emit an oversized block into
# the target -> the exact deploy-time sizing abend this whole BLKSIZE machinery
# exists to prevent (and mbt's SHA256 stamps make a stale large-block member the
# LIKELY first-deploy state).  ld370 must REFUSE on the host, not emit it.
printf '\n=== --blocksize: pack-time guard rejects an oversized member block ===\n'
"$LD" -o "$TMP/bt15" --name BIGTXT "$TMP/bigtxt.o" -iebcopy 2>/dev/null   # built at 15040 -> 13312 blocks
if "$LD" --pack "BIGTXT=$TMP/bt15.iebcopy" --blocksize 6144 -o "$TMP/btpack" -iebcopy 2>/dev/null; then
    echo "  FAIL: packed a 13312-B block into a 6144 library (guard absent)"; fails=$((fails + 1))
else
    echo "  OK: guard refused the oversized member block (13312 > 6144)"
fi

# --norent / --noreus: clear the PDS2ATR1 reentrant / reusable attributes for a
# module that must not be marked RENT (a REXX370 module needs this).  The template
# marks every module RENT+REUS; RENT (0x80) implies REUS (0x40).  --norent clears
# RENT (-> serially reusable), --noreus clears REUS, both clear both.  Applied at
# build like --ac; a --pack of a -iebcopy preserves the member's OWN attributes
# (set at ITS build), so per-member attributes mix in one library.  ATR1 = ud[8] =
# first dir entry (env 328 + count12 + key8 + used2 + name8+ttr3+c1).  tiny is a
# single-block no-RLD module so 1BLK (0x01) is set too: default C3, not C2.
printf '\n=== --norent / --noreus: PDS2ATR1 attribute overrides ===\n'
"$AS" -o "$TMP/attr.o" "$FIX/tiny.s" 2>/dev/null
get_atr1() {                                   # $1 = flags -> echo first member's ATR1 (hex)
    # shellcheck disable=SC2086
    "$LD" $1 -o "$TMP/attr" --name ATTR "$TMP/attr.o" -iebcopy 2>/dev/null
    python3 - "$TMP/attr.iebcopy" <<'PY'
import sys
b = open(sys.argv[1], 'rb').read()
print("%02x" % b[328 + 12 + 8 + 2 + 20])       # env+count12+key8+used2 -> entry; +20 = ud[8]=ATR1
PY
}
expect_atr1() {                                # $1=flags $2=want $3=label
    got=$(get_atr1 "$1")
    if [ "$got" = "$2" ]; then echo "  OK: $3 -> ATR1=$got"
    else echo "  FAIL: $3 ATR1=$got (want $2)"; fails=$((fails + 1)); fi
}
expect_atr1 ""                  c3 "default           (RENT REUS)"
expect_atr1 "--norent"          43 "--norent          (REUS, not RENT)"
expect_atr1 "--noreus"          83 "--noreus          (RENT, not REUS)"
expect_atr1 "--norent --noreus" 03 "--norent --noreus (neither)"
# a --pack of the pre-built -iebcopy must PRESERVE the member's cleared RENT
"$LD" --norent -o "$TMP/nrb" --name NRB "$TMP/attr.o" -iebcopy 2>/dev/null
"$LD" --pack "NRB=$TMP/nrb.iebcopy" -o "$TMP/nrpack" -iebcopy 2>/dev/null
pa=$(python3 - "$TMP/nrpack.iebcopy" <<'PY'
import sys
b = open(sys.argv[1], 'rb').read(); print("%02x" % b[328 + 12 + 8 + 2 + 20])
PY
)
if [ "$pa" = "43" ]; then echo "  OK: --pack preserves the member's cleared RENT (ATR1=$pa)"
else echo "  FAIL: --pack did not preserve --norent (ATR1=$pa)"; fails=$((fails + 1)); fi

# dropped-text on early-ref / late-def section (S106-0F on FETCH of large modules).
# The text packer walked sections in gid order (G[] creation order) but ASSUMED
# origin order.  A section referenced early (low gid) but DEFINED in the last linked
# object (high origin) -- e.g. REXX370's ISTSO, an ER resolved to an SD in the last
# object -- broke that assumption: the packer cut the chunk at the out-of-order
# section and SKIPPED every section in between, silently dropping their text (241 KB
# in IRX#HELO).  The half-loaded module then failed program fetch with S106 reason
# 0F (permanent I/O error, NOT a bad record).  Reproduce: RA (defined first) refs
# RLATE; RB is a big (20 KB) section; RLATE is defined LAST -> RLATE gets a low gid
# but the highest origin, with RB between.  All text must be emitted.
printf '\n=== dropped-text: early-ref / late-def section keeps all text (S106-0F) ===\n'
printf 'RA       CSECT\n         DC    V(RLATE)\n         BR    14\n         END\n'   > "$TMP/ra.s"
printf 'RB       CSECT\n         DC    5000F'\''1'\''\n         BR    14\n         END\n' > "$TMP/rb.s"
printf 'RLATE    CSECT\n         BR    14\n         END\n'                            > "$TMP/rc.s"
for m in ra rb rc; do "$AS" -o "$TMP/$m.o" "$TMP/$m.s" 2>/dev/null; done
"$LD" -o "$TMP/s106" "$TMP/ra.o" "$TMP/rb.o" "$TMP/rc.o" 2>/dev/null
ts=$(python3 - "$TMP/s106" <<'PY'
import sys
def be16(b,o): return (b[o]<<8)|b[o+1]
b=open(sys.argv[1],'rb').read(); n=len(b); p=0
while p<n and (b[p]&0xF0)==0x20: p+=8+be16(b,p+6)   # CESD
while p<n and b[p]==0x80: p+=b[p+1]+1               # IDR
ts=0
while p<n:
    lo=b[p]&0x0F
    if lo in (0x01,0x05,0x0D):
        idlen=be16(b,p+4); tl=be16(b,p+14); ts+=tl; p+=16+idlen+tl
    elif lo in (0x02,0x06,0x0E): p+=16+be16(b,p+6)
    else: break
print(ts)
PY
)
if [ "${ts:-0}" -ge 20000 ]; then
    echo "  OK: big section's text emitted (text=$ts, not dropped)"
else
    echo "  FAIL: text dropped (text=$ts, big RB section skipped -> S106-0F on fetch)"; fails=$((fails + 1))
fi

# >4 MB multi-member pack must not overflow the formerly-fixed 4 MB unload/XMIT
# buffers (same fixed-buffer class as the rld/ld, multi-block-dir and link-table
# fixes).  A 45-module rexx370 test pack (~15.5 MB) SIGBUS'd writing past unl[4 MB];
# write_unload_mem/write_xmit now malloc to the data.  Build one ~400 KB member,
# pack 12 copies (~4.8 MB unload).  Pre-fix this crashed (rc=139) -> the if fails.
printf '\n=== >4MB pack: unload/XMIT buffers grow on demand (no SIGBUS) ===\n'
{ echo "BIG4MB   CSECT"; echo "         DC    100000F'1'"; echo "         BR    14"; echo "         END"; } > "$TMP/big4.s"
"$AS" -o "$TMP/big4.o" "$TMP/big4.s" 2>/dev/null
"$LD" -o "$TMP/big4" --name BIG4MB "$TMP/big4.o" -iebcopy 2>/dev/null
big4specs=""
for i in 00 01 02 03 04 05 06 07 08 09 10 11; do big4specs="$big4specs M$i=$TMP/big4.iebcopy"; done
# shellcheck disable=SC2086
if "$LD" --pack $big4specs -o "$TMP/big4pack" -xmit --dsn X.Y.LINKLIB 2>/dev/null; then
    sz=$(wc -c < "$TMP/big4pack.xmit")
    if [ "$sz" -gt 4194304 ]; then
        echo "  OK: packed ${sz}-byte XMIT (>4MB, no buffer overflow)"
    else
        echo "  FAIL: XMIT only ${sz} bytes (expected >4MB)"; fails=$((fails + 1))
    fi
else
    echo "  FAIL: ld370 --pack of a >4MB member set failed/crashed"; fails=$((fails + 1))
fi

printf '\n'
if [ "$fails" -eq 0 ]; then
    echo "ld370 regression: ALL GREEN"
else
    echo "ld370 regression: $fails FAILED"
fi
exit "$fails"
