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

# Pin the LKED-IDR clock. Every link stamps the current date/time into that
# record, so two separate ld370 runs differ in those 7 bytes whenever they
# straddle a second boundary -- and the autocall/conflict cases below byte-
# compare exactly that: two independent links. Pinning makes them deterministic
# (and lets the IDR content test at the end assert the packed fields).
LDDATE=26223 LDTIME=220517
export LDDATE LDTIME

COMMON="common/src/mvs370.c common/src/obj370.c"
CF="-O2 -Wall -Wextra -Werror -Icommon/include"
[ -x "$AS" ] || gcc $CF -Ias370/include -o "$AS" as370/src/as370.c $COMMON || exit 2
gcc $CF -o "$LD" ld370/src/ld370.c $COMMON || exit 2
gcc $CF -o "$AR" ar370/src/ar370.c $COMMON || exit 2
FI=./file370/file370
gcc $CF -o "$FI" file370/src/file370.c $COMMON || exit 2

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

# cc370#37: a bare .lm packs at entry 0 and at THIS command's attributes, and
# until now said nothing.  The cost is not the AC alone -- an unauthorized module
# is indistinguishable from an authorized one until it runs, and then the first
# MODESET ends the step S047 with an EMPTY SYSPRINT, because the stdio buffers go
# with the unclosed DCB.  So the symptom is "no output and an abend" with nothing
# pointing at the link step; it cost two deploy cycles.
#
# A WARNING and not a refusal, and the reason is measured rather than cautious:
# twelve --pack call sites in THIS file and one in run_2mem_mvs.py pack a bare
# member on purpose (the geometry and multi-block-directory families, where the
# directory metadata is not what is under test), every one of them shaped
# `if "$LD" --pack ...`, so a non-zero rc would fail CI on the commit that added
# it.  The rc assertion below is that control, not a formality.
#
# The three cases separate what the message must say.  A bare member gets the
# warning; the .iebcopy form must stay SILENT (it loses nothing, and a warning
# there would be noise on the path everything in mbt takes); and the AC in the
# text must be the one actually applied -- --ac DOES work on the bare path, which
# is how libc370's authorized probes are built, so a message that said
# "attributes cannot survive" would be wrong for exactly those callers.
printf '\n=== --pack of a bare .lm warns (entry 0 + the AC in force), .iebcopy stays silent ===\n'
pw_fails=0
pw=$("$LD" --pack "NZENT=$TMP/nzent_lnk" -o "$TMP/pw_bare" -iebcopy 2>&1 >/dev/null)
pw_rc=$?
case "$pw" in
    *"bare load module"*) echo "  OK: bare .lm is diagnosed" ;;
    *) echo "  FAIL: bare .lm packed silently: [$pw]"; pw_fails=1 ;;
esac
if [ "$pw_rc" -eq 0 ]; then echo "  OK: it is a warning, rc still 0 (the suite's own bare packs keep working)"
else echo "  FAIL: bare .lm pack now exits $pw_rc -- that breaks 13 call sites"; pw_fails=1; fi
case "$pw" in
    *"entry 0"*) echo "  OK: the message names the entry point it packed at" ;;
    *) echo "  FAIL: the message does not name the entry: [$pw]"; pw_fails=1 ;;
esac
pwa=$("$LD" --pack "NZENT=$TMP/nzent_lnk" --ac 1 -o "$TMP/pw_ac" -iebcopy 2>&1 >/dev/null)
case "$pwa" in
    *"AC 1"*) echo "  OK: it reports the AC actually applied (--ac works on the bare path)" ;;
    *) echo "  FAIL: --ac 1 not reflected in the warning: [$pwa]"; pw_fails=1 ;;
esac
pwi=$("$LD" --pack "NZENT=$TMP/nzent_lnk.iebcopy" -o "$TMP/pw_ieb" -iebcopy 2>&1 >/dev/null)
if [ -z "$pwi" ]; then echo "  OK: the .iebcopy form is silent (nothing is lost, nothing is said)"
else echo "  FAIL: .iebcopy pack warned: [$pwi]"; pw_fails=1; fi
# A -iebcopy member keeps the entry its directory holds; --entry names a BARE
# member's entry (#850), so on this form it is said not to apply.
pwe=$("$LD" --pack "NZENT=$TMP/nzent_lnk.iebcopy" --entry NOSUCHSY -o "$TMP/pw_e" -iebcopy 2>&1 >/dev/null)
case "$pwe" in
    *"does not apply"*) echo "  OK: --entry on a -iebcopy member is diagnosed instead of dropped" ;;
    *) echo "  FAIL: --entry on a -iebcopy member not diagnosed: [$pwe]"; pw_fails=1 ;;
esac
# #850: a bare member's entry comes from its CESD -- @@CRT0, or --entry NAME.
# It sat at 0 only while crt0.o was linked first; with the CRT pulled by autocall
# (libc370#159) @@CRT0 follows the program, and a pack at 0 starts the module in
# the wrong place.  The packed bare member must equal the direct -iebcopy link.
"$AS" -o "$TMP/pkfirst.o" "$FIX/pkfirst.s" && "$AS" -o "$TMP/pkcrt.o" "$FIX/pkcrt.s" \
  && "$LD" -o "$TMP/pk_direct" --name CRTX --entry @@CRT0 "$TMP/pkfirst.o" "$TMP/pkcrt.o" -iebcopy \
  && "$LD" -o "$TMP/pk_bare" --name CRTX "$TMP/pkfirst.o" "$TMP/pkcrt.o" --entry @@CRT0
"$LD" --pack "CRTX=$TMP/pk_bare" -o "$TMP/pk_packed" -iebcopy 2>/dev/null
if cmp -s "$TMP/pk_direct.iebcopy" "$TMP/pk_packed.iebcopy" \
   && "$FI" -v "$TMP/pk_packed.iebcopy" | grep -q 'member CRTX .*entry=000018'; then
    echo "  OK: bare member packed at @@CRT0 (x18), byte-identical to the direct -iebcopy"
else echo "  FAIL: bare member not packed at @@CRT0: $("$FI" -v "$TMP/pk_packed.iebcopy" | grep 'member CRTX')"; pw_fails=1; fi
"$LD" --pack "CRTX=$TMP/pk_bare" --entry GO -o "$TMP/pk_go" -iebcopy 2>/dev/null
"$FI" -v "$TMP/pk_go.iebcopy" | grep -q 'member CRTX .*entry=00001A' \
    && echo "  OK: --entry GO picks the LR at x1A" || { echo "  FAIL: --entry GO not honoured"; pw_fails=1; }
"$LD" --pack "CRTX=$TMP/pk_bare" --entry NOSUCH -o "$TMP/pk_no" -iebcopy 2>"$TMP/pk_no.err"; r=$?
[ $r = 1 ] && grep -q 'not in the CESD' "$TMP/pk_no.err" \
    && echo "  OK: --entry naming nothing in the CESD is refused, rc 1" || { echo "  FAIL: --entry NOSUCH rc $r"; pw_fails=1; }
case "$pw" in
    *"no @@CRT0 in its CESD"*) echo "  OK: without @@CRT0 the entry stays 0 and the warning says why" ;;
    *) echo "  FAIL: entry-0 fallback not explained: [$pw]"; pw_fails=1 ;;
esac
[ "$pw_fails" -eq 0 ] || fails=$((fails + 1))

# #894: --pack links nothing, so a link input on the same command -- an object
# or archive named before --pack, an -l or -L anywhere -- used to be dropped
# without a word (rc 0, the library short a member).  --pack with no member at
# all linked the earlier operands instead.  Both are refused, rc 2, nothing written.
printf '\n=== --pack refuses link inputs and an empty pack (#894) ===\n'
po_fails=0
rm -f "$TMP/po1.xmit" "$TMP/po2.xmit" "$TMP/po3" "$TMP/po3.xmit" "$TMP/po4.xmit"
"$LD" "$TMP/tiny.ld.bin" --pack "RLDT=$TMP/rldt.ld.bin" -o "$TMP/po1" -xmit 2>"$TMP/po1.err"; r=$?
if [ $r = 2 ] && grep -q "tiny.ld.bin" "$TMP/po1.err" && [ ! -e "$TMP/po1.xmit" ]; then
    echo "  OK: an operand before --pack is refused by name, rc 2, no XMIT"
else echo "  FAIL: operand before --pack: rc $r, [$(cat "$TMP/po1.err")], xmit $( [ -e "$TMP/po1.xmit" ] && echo written || echo absent)"; po_fails=1; fi
"$LD" --pack "TINY=$TMP/tiny.ld.bin" -L "$TMP" -o "$TMP/po2" -xmit 2>"$TMP/po2.err"; r=$?
if [ $r = 2 ] && grep -q -- "-L" "$TMP/po2.err" && [ ! -e "$TMP/po2.xmit" ]; then
    echo "  OK: -L with --pack is refused, rc 2"
else echo "  FAIL: -L with --pack: rc $r, [$(cat "$TMP/po2.err")]"; po_fails=1; fi
"$LD" --pack "TINY=$TMP/tiny.ld.bin" -lnosuch -o "$TMP/po4" -xmit 2>"$TMP/po4.err"; r=$?
if [ $r = 2 ] && grep -q -- "-lnosuch" "$TMP/po4.err" && [ ! -e "$TMP/po4.xmit" ]; then
    echo "  OK: -l with --pack is refused, rc 2 (not searched)"
else echo "  FAIL: -l with --pack: rc $r, [$(cat "$TMP/po4.err")]"; po_fails=1; fi
"$LD" -o "$TMP/po3" "$TMP/tiny.ld.bin" -xmit --pack 2>"$TMP/po3.err"; r=$?
if [ $r = 2 ] && [ ! -e "$TMP/po3" ] && [ ! -e "$TMP/po3.xmit" ]; then
    echo "  OK: --pack with no member is refused, rc 2, nothing linked"
else echo "  FAIL: empty --pack: rc $r, [$(cat "$TMP/po3.err")]"; po_fails=1; fi
"$LD" --pack "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" -o "$TMP/po5" -xmit 2>/dev/null \
    && "$FI" "$TMP/po5.xmit" | grep -q 'member' \
    && echo "  OK: --pack first still packs" || { echo "  FAIL: a correct --pack broke"; po_fails=1; }
[ "$po_fails" -eq 0 ] || fails=$((fails + 1))

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
   && "$LD" -e REF "$TMP/ref.o" "$TMP/bigrld.o" -iebcopy --name BIGRLD -o "$TMP/bigrld_link" 2>/dev/null; then
    echo "  OK: GO (LD in a >512-RLD object) resolved across objects"
else
    echo "  FAIL: GO unresolved -- rld[]/ld[] overflow regressed"; fails=$((fails + 1))
fi

# WX (weak external) promotion, issue #99.  g_intern set a composite entry's type
# only when it CREATED the entry, so a WXTRN parsed before a hard EXTRN of the
# same name left the entry at 0x0A for the rest of the link; the unresolved
# check compares == T_ER exactly, so it never fired -- the link came back rc 0
# with a zero adcon and S0C4'd on first use.  Order was the whole bug, so both
# orders are asserted, not just the failing one.
#
# The other half matters more than the bug: an UNMATCHED weak external must stay
# weak (rc 0, CESD type 0A) -- that is the mechanism @@crt0's WXTRN @@STKLEN and
# the entry-point work (#10, #107) rest on.  A promotion that fired
# unconditionally would pass the first three checks and destroy it.
printf '\n=== WX/ER promotion + weak externals stay weak (issue #99) ===\n'
printf 'WXA      CSECT\n         WXTRN WXUNDEF\n         DC    A(WXUNDEF)\n         BR    14\n         END\n' > "$TMP/wxa.s"
printf 'WXB      CSECT\n         EXTRN WXUNDEF\n         DC    A(WXUNDEF)\n         BR    14\n         END\n' > "$TMP/wxb.s"
printf 'WXC      CSECT\n         WXTRN WXUNDEF\n         DC    A(WXUNDEF)\n         BR    14\n         END\n' > "$TMP/wxc.s"
wx_fails=0
for m in wxa wxb wxc; do
    "$AS" -o "$TMP/$m.o" "$TMP/$m.s" 2>/dev/null || { echo "  FAIL: as370 $m"; wx_fails=1; }
done
# WX+ER, BOTH orders: nothing defines WXUNDEF, so the hard ER must be reported.
for pair in "wxa wxb" "wxb wxa"; do
    # shellcheck disable=SC2086
    set -- $pair
    if "$LD" -o "$TMP/wx_$1$2.lm" --name WXM "$TMP/$1.o" "$TMP/$2.o" 2>/dev/null; then
        echo "  FAIL: $1+$2 linked rc 0 -- hard ER unreported (WX promotion regressed)"; wx_fails=1
    else
        echo "  OK: $1+$2 -> unresolved external reported"
    fi
done
# ...and the promoted composite entry is a hard ER (02) in the CESD, as HEWLFESD
# rewrites it in place -- not merely reported and left 0A.
if "$LD" -o "$TMP/wx_prom.lm" --name WXM --allow-unresolved "$TMP/wxa.o" "$TMP/wxb.o" 2>/dev/null; then
    python3 ld370/tests/wx_check.py "$TMP/wx_prom.lm" WXUNDEF=02 || wx_fails=1
else
    echo "  FAIL: --allow-unresolved link failed"; wx_fails=1
fi
# lone WX, and WX+WX in both orders: still weak -- link clean, CESD type stays 0A.
for spec in "lone $TMP/wxa.o" "wxa+wxc $TMP/wxa.o $TMP/wxc.o" "wxc+wxa $TMP/wxc.o $TMP/wxa.o"; do
    # shellcheck disable=SC2086
    set -- $spec
    lbl=$1; shift
    if "$LD" -o "$TMP/wx_$lbl.lm" --name WXW "$@" 2>/dev/null; then
        printf '  %s: ' "$lbl"
        python3 ld370/tests/wx_check.py "$TMP/wx_$lbl.lm" WXUNDEF=0a || wx_fails=1
    else
        echo "  FAIL: $lbl -- an unmatched weak external must NOT fail the link"; wx_fails=1
    fi
done
[ "$wx_fails" -eq 0 ] || fails=$((fails + 1))

# RLD record boundary: the object's SAMERP continuation bit (0x01, "next item
# on this CARD shares R/P") was inherited verbatim into the load module's RLD
# records.  When a record fills to RLDMAX (236) exactly, the item now LAST in
# the record kept the stale bit -- claiming a continuation item the record does
# not contain (IEWL emits this in 0 of 50 SYS1.LINKLIB records; program fetch
# is count-bounded and unbothered, but libc370's __loadhi() walked one item
# past the record data -> S0C4, issue #41).  600 same-R/P A-cons fill ~10
# records to exactly 236 bytes; every record's last item must have the bit
# clear (the emitter's own |= 0x01 is the only legitimate setter).
printf '\n=== RLD records never end on a claimed continuation (issue #41) ===\n'
{ echo "BIGCONT  CSECT"; echo "GO       BR    14"
  awk 'BEGIN{for(i=0;i<600;i++)print "         DC    A(GO)"}'; echo "         END"; } > "$TMP/bigcont.s"
if "$AS" -o "$TMP/bigcont.o" "$TMP/bigcont.s" 2>/dev/null \
   && "$LD" -o "$TMP/bigcont.lm" --name BIGCONT "$TMP/bigcont.o" 2>/dev/null; then
    python3 ld370/tests/rld_check.py "$TMP/bigcont.lm" || fails=$((fails + 1))
else
    echo "  FAIL: bigcont build/link failed"; fails=$((fails + 1))
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

# Autocall diagnostics (cc370#8), on the sources of the IEWL oracle
# (run_iewl_autocall_oracle.py, MVSCE-LAB JOB01408).  Two members of ONE
# archive defining the resolved name warn by default -- IEWL cannot meet that
# case, its directory holds each name once.  A definer in a later archive is
# silent, as IEWL is (test TA), and named only under --warn-shadow.  An
# autocalled member re-defining an entry warns like IEW0241 (test TC); a
# duplicate CSECT does not, IEWL is silent there (test TC2, cc370#102).  None of
# it may move a byte of the module.
run_multidef() {
    local md_fails=0 m e r
    for m in mdxa mdxb mdma mdww mdmc mdmc2 mdrr mdmd; do
        "$AS" -o "$TMP/$m.o" "$FIX/$m.s" || { echo "as370 failed: $m"; fails=$((fails + 1)); return; }
    done
    "$AR" rc "$TMP/libmdab.a" "$TMP/mdxa.o" "$TMP/mdxb.o" &&
    "$AR" rc "$TMP/libmda.a" "$TMP/mdxa.o" "$TMP/mdww.o" "$TMP/mdrr.o" &&
    "$AR" rc "$TMP/libmdb.a" "$TMP/mdxb.o" || { echo "ar370 failed: md"; fails=$((fails + 1)); return; }
    printf '\n=== autocall diagnostics: several definers of one name (cc370#8) ===\n'
    # md NAME PATTERN COUNT ARGS... : link, expect rc 0 and COUNT stderr lines matching PATTERN
    md() {
        local name=$1 pat=$2 want=$3; shift 3
        e=$("$LD" -o "$TMP/md.$name" "$@" 2>&1 >/dev/null); r=$?
        n=$(printf '%s\n' "$e" | /usr/bin/grep -c -- "$pat")
        if [ "$r" -eq 0 ] && [ "$n" -eq "$want" ]; then echo "  OK: $name ($n warning(s), rc $r)"
        else echo "  FAIL: $name: rc $r, $n line(s) matching '$pat', want $want"; printf '%s\n' "$e" | sed 's/^/      /'; md_fails=1; fi
    }
    md same-archive   "'XX' resolved from mdxa.o in .*libmdab.a; also defined by mdxb.o in the same archive" 1 \
        "$TMP/mdma.o" "$TMP/libmdab.a"
    md xx-explicit    "warning" 0 "$TMP/mdma.o" "$TMP/mdxa.o" "$TMP/libmdab.a"
    md cross-archive  "warning" 0 "$TMP/mdma.o" "$TMP/libmda.a" "$TMP/libmdb.a"
    md warn-shadow    "'XX' resolved from mdxa.o in .*libmda.a; also defined by mdxb.o in .*libmdb.a" 1 \
        --warn-shadow "$TMP/mdma.o" "$TMP/libmda.a" "$TMP/libmdb.a"
    md same-lib-twice "warning" 0 --warn-shadow "$TMP/mdma.o" "$TMP/libmda.a" "$TMP/libmda.a"
    md iew0241        "'DUPL' doubly defined: autocalled member mdww.o in .*libmda.a" 1 \
        "$TMP/mdmc.o" "$TMP/mdmc2.o" "$TMP/libmda.a"
    md dup-csect      "warning" 0 "$TMP/mdmd.o" "$TMP/libmda.a"
    # the diagnostics are output only: each module == the explicit link of its pick
    "$LD" -o "$TMP/md.exp-xa" "$TMP/mdma.o" "$TMP/mdxa.o" 2>/dev/null
    "$LD" -o "$TMP/md.exp-ww" "$TMP/mdmc.o" "$TMP/mdmc2.o" "$TMP/mdww.o" 2>/dev/null
    if cmp -s "$TMP/md.same-archive" "$TMP/md.exp-xa" && cmp -s "$TMP/md.warn-shadow" "$TMP/md.exp-xa" \
       && cmp -s "$TMP/md.iew0241" "$TMP/md.exp-ww"; then
        echo "  OK: a warned link writes the module the explicit link writes"
    else
        echo "  FAIL: a warned link differs from the explicit link"; md_fails=1
    fi
    [ "$md_fails" -eq 0 ] || fails=$((fails + 1))
}

run_multidef

# An ENTRY in a CSECT that is not first in its object (cc370#522).  QE sits at
# x10 of object DCOB, inside QQ (object offset x08).  IEWL puts it at x10 when
# DCOB is linked first (MVSCE-LAB JOB01409, test TE2: CESD, and OD's V(QE)).
# ld370 added the object-relative address to QQ's origin: x18.
run_entry_offset() {
    local eo_fails=0 v c
    for m in dcob dcod; do
        "$AS" -o "$TMP/$m.o" "$FIX/$m.s" || { echo "as370 failed: $m"; fails=$((fails + 1)); return; }
    done
    printf '\n=== an ENTRY in a later CSECT of its object (cc370#522) ===\n'
    v=$("$LD" --verbose -e OD -o "$TMP/eo.lm" "$TMP/dcob.o" "$TMP/dcod.o" 2>&1)
    c=$("$FI" -v "$TMP/eo.lm" | /usr/bin/grep -c 'QE  *LR  *addr=000010')
    if printf '%s\n' "$v" | /usr/bin/grep -q 'adcon@000030 -> QE: .*(final 000010)' && [ "$c" -eq 1 ]; then
        echo "  OK: CESD QE at x10 and OD's V(QE) = x10, as IEWL"
    else
        echo "  FAIL: QE is not at x10 (CESD match: $c)"; printf '%s\n' "$v" | /usr/bin/grep -E 'QE' | sed 's/^/      /'; eo_fails=1
    fi
    if "$LD" --verbose -e QE -o "$TMP/eo2.lm" "$TMP/dcob.o" "$TMP/dcod.o" 2>&1 | /usr/bin/grep -q -- '--entry QE -> 000010'; then
        echo "  OK: --entry QE resolves to x10"
    else
        echo "  FAIL: --entry QE does not resolve to x10"; eo_fails=1
    fi
    [ "$eo_fails" -eq 0 ] || fails=$((fails + 1))
}

run_entry_offset

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

# 24-bit module length: a text record's load address is written with mvs_put24,
# so a module past 2**24 wraps -- the tail loads over its own entry code, with
# no diagnostic and a member file370 reads as well-formed (#455).  as370 bounds
# each SECTION; this is the sum, which it cannot see.  The two fixtures reserve
# 9,830,100 bytes each: legal alone, 240-byte decks because DS emits no TXT,
# and 19,660,200 together.
printf '\n=== module length: a link past 24-bit addressing is refused ===\n'
"$AS" -o "$TMP/sum24a.o" "$FIX/sum24a.s" >/dev/null 2>&1
"$AS" -o "$TMP/sum24b.o" "$FIX/sum24b.s" >/dev/null 2>&1
if "$LD" -o "$TMP/sum24.lm" --name SUMBIG "$TMP/sum24a.o" "$TMP/sum24b.o" >/dev/null 2>&1; then
    echo "  FAIL: linked a 19,660,200-byte module; its load addresses wrap at 2**24"
    fails=$((fails + 1))
else
    echo "  OK: refused a module past 24-bit addressing"
fi
# and one half must still link, or the bound is simply too tight
if "$LD" -o "$TMP/sum24half.lm" --name SUMHALF "$TMP/sum24a.o" >/dev/null 2>&1; then
    echo "  OK: one 9,830,100-byte section still links"
else
    echo "  FAIL: refused a section that is inside 2**24"; fails=$((fails + 1))
fi

# --sparse-text: the flag may drop a DS reservation, which no TXT card covers,
# and must NOT drop DC zeros, which a programmer wrote and which ARE text.  In
# the loaded module the two regions are identical bytes; only the object deck
# tells them apart, which is exactly why the first version of this flag tested
# the byte value and silently dropped both (#445, caught by the DC 8000F'0' in
# the blocksize fixture above).  The fixture carries one of each with markers
# between, and sparse_scan.py takes its expectations from the deck rather than
# from offsets written down here.
printf '\n=== --sparse-text: elides a DS reservation, keeps DC zeros ===\n'
if "$AS" -o "$TMP/sparse.o" "$FIX/sparse.s" >/dev/null 2>&1 &&
   "$LD" -o "$TMP/sparse_off" --name SPARSE "$TMP/sparse.o" >/dev/null 2>&1 &&
   "$LD" --sparse-text -o "$TMP/sparse_on" --name SPARSE "$TMP/sparse.o" >/dev/null 2>&1
then
    python3 ld370/tests/sparse_scan.py "$TMP/sparse.o" "$TMP/sparse_off" "$TMP/sparse_on" \
        || fails=$((fails + 1))
    if cmp -s "$TMP/sparse_off" "$TMP/sparse_on"; then
        echo "  FAIL: --sparse-text produced the same member as the default"
        fails=$((fails + 1))
    fi
else
    echo "  FAIL: could not assemble or link the sparse fixture"; fails=$((fails + 1))
fi

# PDS2ATR1 reentrant / reusable attributes.  Since cc370#100 the default is
# IEWL's: NEITHER (ATR1 03 -- EXEC|1BLK; IEWL's plain link lists 03F2).  The
# set-flags are orthogonal: --rent sets RENT (83), --reus REUS (43), IEWL's RENT
# is --rent --reus (C3); --norent/--noreus clear, and against the new default
# change nothing.  Applied at build like --ac; a --pack of a -iebcopy preserves the
# member's OWN attributes (set at ITS build), so per-member attributes mix in
# one library.  ATR1 = ud[8] = first dir entry (env 328 + count12 + key8 +
# used2 + name8+ttr3+c1).  tiny is single-block no-RLD, so 1BLK (0x01) is set.
printf '\n=== PDS2ATR1: default neither, --rent / --reus / --norent / --noreus ===\n'
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
expect_atr1 ""                  03 "default           (neither -- IEWL's default)"
expect_atr1 "--rent"            83 "--rent            (RENT only -- the flags are orthogonal)"
expect_atr1 "--rent --reus"     c3 "--rent --reus     (RENT REUS, IEWL's RENT)"
expect_atr1 "--reus"            43 "--reus            (REUS, not RENT)"
expect_atr1 "--norent --reus"   43 "--norent --reus   (REUS, not RENT)"
expect_atr1 "--norent"          03 "--norent          (neither)"
expect_atr1 "--norent --noreus" 03 "--norent --noreus (neither)"
# a --pack of the pre-built -iebcopy must PRESERVE the member's own attributes
"$LD" --reus -o "$TMP/nrb" --name NRB "$TMP/attr.o" -iebcopy 2>/dev/null
"$LD" --pack "NRB=$TMP/nrb.iebcopy" -o "$TMP/nrpack" -iebcopy 2>/dev/null
pa=$(python3 - "$TMP/nrpack.iebcopy" <<'PY'
import sys
b = open(sys.argv[1], 'rb').read(); print("%02x" % b[328 + 12 + 8 + 2 + 20])
PY
)
if [ "$pa" = "43" ]; then echo "  OK: --pack preserves the member's own REUS (ATR1=$pa)"
else echo "  FAIL: --pack did not preserve --reus (ATR1=$pa)"; fails=$((fails + 1)); fi

# ---- --rent / --reus / --refr: SET the attributes (cc370#100) --------------
# Measured against IEWL itself on MVS 3.8j (mvsdev, 2026-09-23), because a bit
# position checked only against our own decoder is checked against the same
# assumption that encoded it.  One IFOX00 assembly, three IEWL links differing
# only in PARM, read back with IEHLIST -- IBM's linker setting the bits and
# IBM's lister naming them:
#
#   PLAIN     PARM='NCAL,LIST,XREF'             ATTR 03F2
#   WITHREFR  PARM='NCAL,LIST,XREF,REFR'        ATTR 03F3
#   RENTREFR  PARM='NCAL,LIST,RENT,REFR'        ATTR C3F3
#
# and IEHLIST's own ATTRIBUTE INDEX: bit 0 RENT, bit 1 REUS, bit 6 EXEC,
# bit 7 "1 TXT", bit 11 "NO RLD", **bit 15 REFR** -- the low bit of the SECOND
# byte.  So REFR is PDS2ATR2, ud[9] 0x01, and IHAPDS agrees (PDS2REFR EQU BIT7
# under PDS2ATR2).  cc370#100's text and internals/ld370-iewl-divergences.md both
# said PDS2ATR1; writing it there would have set 0x01 of ATR1, which is
# PDS21BLK and already on -- a --refr that changes nothing and looks done.
#
# Our own members, installed on the same system and listed by the same IEHLIST:
#
#   --norent --noreus          03F2   == IEWL's PLAIN
#   --norent --noreus --refr   03F3   == IEWL's WITHREFR
#
# The default is inverted now (cc370#100), so the plain link is IEWL's PLAIN
# byte for byte and --rent/--reus are no longer idempotent.
printf '\n=== --rent / --reus / --refr: PDS2 attribute set-flags ===\n'
get_atr() {                                    # $1 = flags -> "ATR1 ATR2" in hex
    # shellcheck disable=SC2086
    "$LD" $1 -o "$TMP/sat" --name SAT "$TMP/attr.o" -iebcopy 2>/dev/null
    python3 - "$TMP/sat.iebcopy" <<'JPY'
import sys
b = open(sys.argv[1], 'rb').read()
o = 328 + 12 + 8 + 2 + 20
print("%02x %02x" % (b[o], b[o + 1]))
JPY
}
expect_atr() {                                 # $1=flags $2=want $3=label
    rm -f "$TMP/sat.iebcopy"
    got=$(get_atr "$1")
    if [ "$got" = "$2" ]; then echo "  OK: $3 -> $got"
    else echo "  FAIL: $3 got '$got' (want '$2')"; fails=$((fails + 1)); fi
}
expect_atr ""                            "03 f2" "default                  == IEWL's PLAIN"
expect_atr "--refr"                      "03 f3" "--refr                   == IEWL's WITHREFR"
expect_atr "--norent --noreus"           "03 f2" "--norent --noreus        == IEWL's PLAIN"
expect_atr "--rent --reus --refr"        "c3 f3" "--rent --reus --refr     == IEWL's RENTREFR"
expect_atr "--rent --reus"               "c3 f2" "--rent --reus            (RENT REUS)"
# A set/clear pair is refused, and nothing is written -- there is no half-built
# member to mistake for output.
# The MESSAGE is asserted, not just the failure.  A build that does not know
# --rent treats it as an object file and fails too, so "it did not write a
# member" is satisfied for the wrong reason -- measured: this check passed
# against origin/main before the flags existed.
rm -f "$TMP/contra" "$TMP/contra.iebcopy"
"$LD" --rent --norent -o "$TMP/contra" --name C "$TMP/attr.o" -iebcopy \
      >"$TMP/contra.out" 2>&1
crc=$?
if [ $crc = 0 ]; then
    echo "  FAIL: --rent with --norent was accepted"; fails=$((fails + 1))
elif [ -f "$TMP/contra.iebcopy" ]; then
    echo "  FAIL: --rent with --norent refused but still wrote a member"; fails=$((fails + 1))
elif ! grep -q "opposite attributes" "$TMP/contra.out"; then
    echo "  FAIL: --rent with --norent failed for the wrong reason:"; sed 's/^/        /' "$TMP/contra.out"
    fails=$((fails + 1))
else
    echo "  OK: --rent with --norent is refused BY NAME and writes nothing"
fi

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
printf '\n=== #837: common (CM) sections after every object, longest wins ===\n'
# IEWL on MVSTK5-REF (JOB00352; map + AMBLIST in fixtures/cm2.iewl-*.txt):
# CMA 00, CMB 10, then CBLK 20 (x14 -- the longer of x0A and x14) and GBLK 38,
# total x40; text only for the two CSECTs; CESD in order of first appearance.
"$AS" -o "$TMP/cma.o" "$FIX/cma.s" && "$AS" -o "$TMP/cmb.o" "$FIX/cmb.s" \
  && "$LD" -o "$TMP/cm.lm" --name CMTEST --entry CMA "$TMP/cma.o" "$TMP/cmb.o" --map "$TMP/cm.map" --xref 2>/dev/null
"$FI" -v "$TMP/cm.lm" > "$TMP/cm.v" 2>&1
if python3 - "$TMP/cm.lm" "$TMP/cm.v" "$TMP/cm.map" <<'PYCM'
import re, sys
lm = open(sys.argv[1], "rb").read(); v = open(sys.argv[2]).read(); mp = open(sys.argv[3]).read()
rec = [(int(o, 16), k, int(n)) for o, k, n in re.findall(r"@([0-9A-F]{6})\s+(\w+)\s+(\d+) bytes", v)]
def body(kind, nth=0):
    hits = [(o, n) for o, k, n in rec if k == kind]
    o, n = hits[nth]; return lm[o:o + n].hex()
want_cesd = ["CMA SD 000000 00000F", "CBLK CM 000020 000014", "GBLK CM 000038 000008", "CMB SD 000010 00000D"]
got_cesd = [" ".join(m) for m in re.findall(r"CESD\s+\d+\s+(\S+)\s+(\S+)\s+addr=(\w+)\s+len=(\w+)", v)]
ok = got_cesd == want_cesd
ok &= body("control", 0) == "010000000008000006000000400000200001001000040010"   # CCW 06000000 40000020, ids 1/x10 4/x10
ok &= body("text", 0) == "000000200000002400000038aaaaaa00000000200000002cbbbbbbbbbb000000"
# the RLD items behind the 16-byte header: R 2 P 1 0D 0 / 0C 4, R 3 P 1 0C 8, R 2 P 4 0D 10 / 0C 14
ok &= body("control", 1)[32:] == "000200010d0000000c000004000300010c000008000200040d0000100c000014"
ok &= "LENGTH 000040" in mp
# --xref lists the five references to the commons, as IEWL's map does (#845)
ok &= len(re.findall(r"\+0000(?:00|04|08)\s+A\s+(?:CBLK|GBLK)\s+0000(?:20|38)\s+in (?:CBLK|GBLK)", mp)) == 5
sys.exit(0 if ok else 1)
PYCM
then echo "  OK: CM sections allocated after the objects, longest contribution, text CSECTs only (== IEWL JOB00352)"
else echo "  FAIL: CM layout differs from IEWL JOB00352"; fails=$((fails+1)); fi

printf '\n=== #821: pack options, non-member input, write errors, rc classes ===\n'
c821_fails=0
c821() { if [ "$2" = "$3" ]; then echo "  OK: $1"; else echo "  FAIL: $1 (rc $3, want $2)"; c821_fails=1; fi; }
"$AS" -o "$TMP/c821.o" "$FIX/cma.s" && "$LD" -o "$TMP/c821" --name C821 --entry CMA "$TMP/c821.o" -iebcopy 2>/dev/null
"$LD" --pack "A=$TMP/c821.iebcopy" "A=$TMP/c821.iebcopy" -o "$TMP/c821p" -iebcopy 2>/dev/null; c821 "a name used twice in one pack is rc 2" 2 $?
"$LD" --pack "A=$TMP/c821.iebcopy" -i FOO -o "$TMP/c821i" -iebcopy 2>/dev/null; c821 "--include with --pack is rc 2" 2 $?
w=$("$LD" --pack "A=$TMP/c821.iebcopy" --warn-shadow -o "$TMP/c821w" -iebcopy 2>&1 >/dev/null)
case "$w" in *"--warn-shadow is ignored"*) echo "  OK: --warn-shadow with --pack warns" ;; *) echo "  FAIL: --warn-shadow silent: [$w]"; c821_fails=1 ;; esac
printf 'int main(void) { return 0; }\n' > "$TMP/c821.c"
"$LD" --pack "$TMP/c821.c" -o "$TMP/c821c" -iebcopy 2>"$TMP/c821c.err"; r=$?
c821 "a C source under --pack is rc 2" 2 $r
grep -q 'not a load module' "$TMP/c821c.err" && ! grep -q 'bare load module' "$TMP/c821c.err" \
    && echo "  OK: ...and is called not a load module, not a bare one" || { echo "  FAIL: c-source message: $(cat "$TMP/c821c.err")"; c821_fails=1; }
"$LD" -o /nonexist/c821 --name X "$TMP/c821.o" 2>"$TMP/c821n.err"; r=$?
c821 "an unwritable member is rc 1" 1 $r
grep -q '^ld370: cannot write /nonexist/c821' "$TMP/c821n.err" && echo "  OK: ...with the ld370: prefix" || { echo "  FAIL: unprefixed: $(cat "$TMP/c821n.err")"; c821_fails=1; }
rm -f "$TMP/c821m"
"$LD" -o "$TMP/c821m" --name X "$TMP/c821.o" --map /nonexist/c821.map 2>/dev/null; r=$?
c821 "an unwritable --map is rc 1" 1 $r
[ ! -e "$TMP/c821m" ] && echo "  OK: ...found before the member is written" || { echo "  FAIL: member written before the --map failure"; c821_fails=1; }
"$LD" -o "$TMP/c821a" --name X --alias X "$TMP/c821.o" -iebcopy 2>/dev/null; c821 "--alias naming the member is rc 2" 2 $?
rm -rf "$TMP/c821x" "$TMP/c821x.xmit"; mkdir "$TMP/c821x.xmit"
"$LD" -o "$TMP/c821x" --name X --entry CMA "$TMP/c821.o" -xmit 2>/dev/null; r=$?
c821 "an unwritable transport file is rc 1" 1 $r
[ ! -e "$TMP/c821x" ] && echo "  OK: ...found before the member is written" || { echo "  FAIL: member left behind by an unwritable .xmit"; c821_fails=1; }
rmdir "$TMP/c821x.xmit"
[ "$c821_fails" = 0 ] || fails=$((fails + 1))

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

# LKED-IDR content.  lmdiff.py carves the IDR identity records out of every
# byte comparison above, so nothing there would catch a wrong product string,
# version, or a mis-packed date/time -- only a wrong LENGTH byte (the record
# walk would then desync).  Assert the 22 bytes directly, against the pinned
# LDDATE/LDTIME: 80 15 82 | "LD370     " EBCDIC | VV MM | YYDDDF | 0HHMMSSF.
printf '\n=== LKED-IDR: 22-byte record content (product, version, packed date/time) ===\n'
"$AS" -o "$TMP/idr.o" "$FIX/klein.s" 2>/dev/null
"$LD" -o "$TMP/idr.lm" --name IDRT "$TMP/idr.o" 2>/dev/null
if python3 - "$TMP/idr.lm" <<'EOF'
import sys
d = open(sys.argv[1], 'rb').read()
i = d.find(bytes((0x80, 0x15, 0x82)))
if i < 0:
    sys.exit("  FAIL: no LKED IDR (80 15 82) in the record stream")
r = d[i:i + 22]
# version and modification level come from VERSION (#807: a fixed 01 / 00)
import re
vv, mm = (int(x) for x in re.match(r"(\d+)\.(\d+)", open("VERSION").read()).groups())
bcd = lambda v: ((v // 10) << 4) | (v % 10)
want = bytes((0x80, 0x15, 0x82)) \
     + "LD370     ".encode('cp037') \
     + bytes((bcd(vv % 100), bcd(mm % 100), 0x26, 0x22, 0x3f, 0x02, 0x20, 0x51, 0x7f))
if r != want:
    sys.exit("  FAIL: IDR is %s\n         expected %s"
             % (r.hex(' '), want.hex(' ')))
print("  OK: 80 15 82 'LD370     ' V%02d M%02d 26223 22:05:17 (LASTIDR set)" % (vv, mm))
EOF
then :; else fails=$((fails + 1)); fi

# Physical CKD geometry of the unloaded image -- the check ld370 never had.
#
# The over-packed-track bug (S106-0F on FETCH, 2026-06-24) got all the way onto
# real MVS because every host check was lenient in the same way the reload path
# is: unload_check.py finds members through the directory exactly as IEBCOPY
# does, and IEBCOPY does not care how many records a track claims.  Program
# FETCH does, because its channel program positions by each record's on-disk
# count field.  xmit370 has had this assertion since it was written; the tool
# where the bug actually happened did not.
#
# track_check.py is ABSOLUTE, not self-consistent: it costs every record at real
# 3350 rates (185 gap+count + data against a 19254-byte track), demands R be
# 1..n with no hole, requires the UDEBX extent to span every track written, and
# requires every env-header byte the emitter does not stamp to still equal the
# committed template.  A wrong constant fails it; ld370 agreeing with itself
# does not save it.
#
# The two shapes below exist because the constants hide from small inputs.  A
# dense multi-member pack is what makes an under-counted per-record overhead
# over-pack a track at all; a member spanning more than one cylinder is what
# makes a wrong UDEBX end/NMTRK differ from the template's own default.  With
# only the small fixtures above, four of the eight constants tested clean when
# deliberately corrupted.
printf '\n=== unload geometry: 3350 track density, R numbering, UDEBX extent, template ===\n'
geo_fails=0

# (a) dense pack: 40 tiny members -> ~240 records, tracks filled to ~19045/19254
gspecs=""; gi=1
while [ "$gi" -le 40 ]; do
    gm=$(printf 'G%03d' "$gi")
    printf "%-8s CSECT\n         DC    CL64'PAD'\n         BR    14\n         END   %s\n" "$gm" "$gm" > "$TMP/$gm.s"
    "$AS" -o "$TMP/$gm.o" "$TMP/$gm.s" 2>/dev/null
    "$LD" -o "$TMP/$gm.lm" --name "$gm" "$TMP/$gm.o" 2>/dev/null
    gspecs="$gspecs $gm=$TMP/$gm.lm"
    gi=$((gi + 1))
done
# shellcheck disable=SC2086
"$LD" --pack $gspecs --dsn IBMUSER.GEO.LOAD -o "$TMP/geodense" -iebcopy 2>/dev/null \
    || { echo "  FAIL: dense pack did not build"; geo_fails=1; }

# (b) multi-cylinder: a single member is laid out one block per track, so a small
#     --blocksize turns a modest module into 90 tracks = 3 cylinders cheaply.
awk 'BEGIN{print "MCYL     CSECT"; for(i=0;i<11000;i++) printf "         DC    F%c%d%c\n",39,i,39;
           print "         BR    14"; print "         END   MCYL"}' > "$TMP/mcyl.s"
"$AS" -o "$TMP/mcyl.o" "$TMP/mcyl.s" 2>/dev/null
"$LD" --blocksize 1024 -o "$TMP/mcyl.lm" --name MCYL "$TMP/mcyl.o" 2>/dev/null
"$LD" --pack "MCYL=$TMP/mcyl.lm" --blocksize 1024 --dsn IBMUSER.MCYL.LOAD \
    -o "$TMP/geomcyl" -iebcopy 2>/dev/null \
    || { echo "  FAIL: multi-cylinder member did not build"; geo_fails=1; }

# every unloaded image this suite has produced, plus the two shapes above
# --pack-cap: OUR emitters must leave one record's overhead unspent, so no track
# may exceed 19069 even though 19254 is what a 3350 physically holds.  Without it
# the most plausible wrong edit -- "correcting" the packing budget up to the real
# track length -- passes every other check (measured: dense pack 19045 -> 19075).
# It is opt-in because a real IEBCOPY oracle may legally pack past 19069.
python3 ld370/tests/track_check.py --pack-cap \
    "$TMP/geodense.iebcopy" "$TMP/geomcyl.iebcopy" \
    "$TMP/tiny.ld.bin.iebcopy" "$TMP/rldt.ld.bin.iebcopy" "$TMP/klein.ld.bin.iebcopy" \
    "$TMP/lib2.iebcopy" "$TMP/lib3.iebcopy" "$TMP/lib7.iebcopy" "$TMP/lib20.iebcopy" \
    || geo_fails=1

# ...and through the XMIT envelope, which the bare image cannot check: COPYR1 and
# COPYR2 must arrive as two separate logical records of 52 + 276.  RECEIVE reads
# them one record at a time, so a wrong split misreads the DCB with every byte of
# the pair correct.
"$LD" --pack "MCYL=$TMP/mcyl.lm" --blocksize 1024 --dsn IBMUSER.MCYL.LOAD \
    -o "$TMP/geox" -iebcopy -xmit 2>/dev/null
# shellcheck disable=SC2086
"$LD" --pack $gspecs --dsn IBMUSER.GEO.LOAD -o "$TMP/geodensex" -iebcopy -xmit 2>/dev/null
# geodensex is the MULTI-member one: the per-member VS framing that the IEB183I
# fix installed is only exercised through the envelope, and a single member has
# exactly one EOF so it cannot show a framing regression at all.
python3 ld370/tests/track_check.py --from-xmit --pack-cap \
    "$TMP/geox.xmit" "$TMP/geodensex.xmit" "$TMP/e2e.xmit" \
    || geo_fails=1
# A single member is laid out one block per track; a multi-member pack fills
# tracks.  Pinning both counts catches a changed packing POLICY, which leaves
# every geometry rule satisfied and still emits a different image.
python3 ld370/tests/track_check.py --pack-cap --max-tracks 90 "$TMP/geomcyl.iebcopy" \
    || geo_fails=1
python3 ld370/tests/track_check.py --pack-cap --max-tracks 4 "$TMP/geodense.iebcopy" \
    || geo_fails=1
[ "$geo_fails" -eq 0 ] || fails=$((fails + 1))

# Scatter/translation record (byte 0 = X'10').  A module bound SCTR or OVLY
# carries one after its CESD and IDRs; neither cc370 nor as370 emits one, so the
# record walk had never met it and stopped dead -- file370 reported
# "TRUNCATED/unrecognized", cmplmd370 "malformed load-module record stream".  A
# tree-wide run over 5,252 real DLIB members found 22 that carry one, almost all
# ICK*, and every one of them was unreadable.
#
# internals/load-module-format.md section 8: byte 0 = X'10', bytes 1-3 = the DATA
# byte count, 4-byte header, so the record is 4 + count.  The fixture is built
# here rather than committed, by splicing a record of that exact shape into a
# real IEWL member after its IDRs -- the position section 2 gives it.
printf '\n=== scatter/translation record is walked, not treated as the end ===\n'
python3 - "$FIX/e2e.iewl-member.bin" "$TMP/scatter.lm" <<'EOF'
import sys
src = open(sys.argv[1], 'rb').read()
p = 0
while p < len(src) and (src[p] & 0xF0) in (0x20, 0x80):      # CESD and IDR records
    p += (8 + ((src[p+6] << 8) | src[p+7])) if (src[p] & 0xF0) == 0x20 else src[p+1] + 1
data = bytes(range(16))
open(sys.argv[2], 'wb').write(
    src[:p] + bytes([0x10]) + len(data).to_bytes(3, 'big') + data + src[p:])
EOF
sc_before=$("$FI" "$FIX/e2e.iewl-member.bin")
sc_after=$("$FI" "$TMP/scatter.lm")
if printf '%s' "$sc_after" | grep -q "TRUNCATED"; then
    echo "  FAIL: the scatter record still ends the walk: $sc_after"
    fails=$((fails + 1))
elif ! printf '%s' "$sc_after" | grep -q "1 scatter"; then
    echo "  FAIL: the scatter record was not reported: $sc_after"
    fails=$((fails + 1))
elif [ "$(printf '%s' "$sc_before" | sed 's/.*-- //;s/, [0-9]* bytes.*//')" \
     != "$(printf '%s' "$sc_after" | sed 's/.*-- //;s/1 scatter, //;s/, [0-9]* bytes.*//')" ]; then
    echo "  FAIL: the records after the scatter record changed"
    echo "        before: $sc_before"
    echo "        after:  $sc_after"
    fails=$((fails + 1))
else
    echo "  OK: scatter record walked (4 + count), every later record unchanged"
fi

# XMIT reproducibility.  LDDATE/LDTIME exist so a link is byte-comparable between
# two runs, but until 2026-09-06 they pinned only the LKED IDR: emit_xmit's
# INMFTIME still read the wall clock, so every ld370 .xmit differed from itself
# across a second boundary and could not be byte-compared at all.  Two runs a
# second apart must now produce an identical file, and INMFTIME must decode to
# the pinned instant -- LDDATE=26223 is 2026 day 223 = 11 August, LDTIME=220517.
# The decode half matters as much as the identity half: a stamp frozen at a WRONG
# constant value would be perfectly reproducible and still wrong.
printf '\n=== XMIT is byte-reproducible under LDDATE/LDTIME, and INMFTIME decodes ===\n'
"$AS" -o "$TMP/ftm.o" "$FIX/tiny.s" 2>/dev/null
"$LD" -o "$TMP/ftm.lm" --name FTM "$TMP/ftm.o" 2>/dev/null
"$LD" --pack "FTM=$TMP/ftm.lm" --dsn IBMUSER.FTM.LOAD -o "$TMP/ftm1" -iebcopy -xmit 2>/dev/null
sleep 1
"$LD" --pack "FTM=$TMP/ftm.lm" --dsn IBMUSER.FTM.LOAD -o "$TMP/ftm2" -iebcopy -xmit 2>/dev/null
if cmp -s "$TMP/ftm1.xmit" "$TMP/ftm2.xmit"; then
    if python3 - "$TMP/ftm1.xmit" <<'EOF'
import sys
d = open(sys.argv[1], 'rb').read()
want = "2026081122051700"
got = d[75:91].decode('cp037')
if got != want:
    sys.exit("  FAIL: INMFTIME is %r, expected %r (LDDATE=26223 LDTIME=220517)" % (got, want))
print("  OK: two runs identical, INMFTIME = %s" % got)
EOF
    then :; else fails=$((fails + 1)); fi
else
    echo "  FAIL: two pinned runs produced different .xmit -- INMFTIME is not pinned"
    fails=$((fails + 1))
fi

# --alias (#466): the directory IEWL writes for ALIAS statements, byte for byte.
# fixtures/alias.iewl.xmit is IEWL's own library (MVSCE-LAB JOB01367): altest.s
# linked as BREXX (ALIAS RX1, RX2), ALTM (ALIAS ALT2 -- an ENTRY of the module,
# so its alias enters at X'14', not X'10') and ACM (SETCODE AC(1), ALIAS ACA).
# alias_check.py compares every entry masked only at the layout-dependent TTR
# and PDS2TTRT; --layout also compares the directory blocks, which IEWL fills by
# bytes: 6 entries in the first (248 of 256), RX2 alone in the second.  The
# pre-change ld370 refuses --alias (rc 1), and its pack of the three members
# alone fails on the names and on the blocks.
printf '\n=== --alias: the directory IEWL writes for ALIAS (JOB01367) ===\n'
# Every output is removed first and every link's rc is checked: a link that
# fails writes nothing, and a checker reading the previous run's file passes on a
# binary that cannot do this at all -- which is how this section first scored
# green against the pre-change ld370.
for f in altb altm altc altlib many manyp manyr; do
    rm -f "$TMP/$f" "$TMP/$f.iebcopy" "$TMP/$f.xmit"
done
alk() { "$@" 2>/dev/null; r=$?; if [ "$r" != 0 ]; then echo "  FAIL: rc $r from: $*" | sed "s|$TMP/||g"; fails=$((fails + 1)); fi; }
"$AS" -o "$TMP/alt.o" "$FIX/altest.s" 2>/dev/null
# The oracle was linked LIST,MAP,XREF,NCAL,RENT,REUS (internals/load-module-format.md),
# so these ask for RENT and REUS too -- ld370's default is neither since #100.
alk "$LD" --rent --reus -o "$TMP/altb" --name BREXX --alias RX1 --alias RX2 "$TMP/alt.o" -iebcopy
alk "$LD" --rent --reus -o "$TMP/altm" --name ALTM --alias ALT2 "$TMP/alt.o" -iebcopy
alk "$LD" --rent --reus -o "$TMP/altc" --name ACM --ac 1 --alias ACA "$TMP/alt.o" -iebcopy
for f in altb altm altc; do
    python3 ld370/tests/alias_check.py "$FIX/alias.iewl.xmit" "$TMP/$f.iebcopy" --subset \
        || fails=$((fails + 1))
done
alk "$LD" --pack "BREXX=$TMP/altb.iebcopy" "ALTM=$TMP/altm.iebcopy" "ACM=$TMP/altc.iebcopy" \
    --dsn IBMUSER.ALT.LOAD -o "$TMP/altlib" -iebcopy -xmit
python3 ld370/tests/alias_check.py "$FIX/alias.iewl.xmit" "$TMP/altlib.iebcopy" --layout \
    || fails=$((fails + 1))
python3 ld370/tests/alias_check.py "$FIX/alias.iewl.xmit" "$TMP/altlib.xmit" --layout \
    || fails=$((fails + 1))
python3 ld370/tests/unload_check.py "$TMP/altlib.iebcopy" BREXX ALTM ACM \
    || fails=$((fails + 1))

# Many aliases spill over several directory blocks, and --pack reads them all
# back: a single-member pack of an aliased -iebcopy reproduces it byte for byte.
# Renaming the member with NAME= re-points every alias's PDS2MNM at the new name.
printf '\n=== --alias: 14 aliases over 3 blocks survive --pack; NAME= renames PDS2MNM ===\n'
alk "$LD" -o "$TMP/many" --name MANY --alias A01 --alias A02 --alias A03 --alias A04 \
    --alias A05 --alias A06 --alias A07 --alias A08 --alias A09 --alias A10 \
    --alias A11 --alias A12 --alias A13 --alias ALT2 "$TMP/alt.o" -iebcopy
alk "$LD" --pack "MANY=$TMP/many.iebcopy" -o "$TMP/manyp" -iebcopy
alk "$LD" --pack "RENAMED=$TMP/many.iebcopy" -o "$TMP/manyr" -iebcopy
if python3 - "$TMP/many.iebcopy" "$TMP/manyp.iebcopy" "$TMP/manyr.iebcopy" <<'EOF'
import sys
sys.path.insert(0, "ld370/tests")
from alias_check import directory
src, pk, rn = (open(f, "rb").read() for f in sys.argv[1:4])
d = directory(src)
shape = [(u, len(es)) for u, k, es in d]
if shape != [(232, 5), (232, 5), (234, 5)]:
    sys.exit("  FAIL: 15 entries laid out as %s, expected 5/5/5 in 232/232/234 bytes" % shape)
if pk != src:
    sys.exit("  FAIL: a single-member --pack of an aliased -iebcopy is not byte-identical to it")
mn = {e[3][24:32].decode("cp037").rstrip() for b in directory(rn) for e in b[2] if e[2] & 0x80}
if mn != {"RENAMED"}:
    sys.exit("  FAIL: after NAME=RENAMED the aliases' PDS2MNM read %s" % sorted(mn))
print("  OK: 3 blocks (5/5/5), pack round trip byte-identical, PDS2MNM follows NAME=")
EOF
then :; else fails=$((fails + 1)); fi

# The refusals.  A name may appear once in a library, whichever kind of entry it
# is; --alias belongs to a link (a pack takes its aliases from its inputs); and
# an alias is a member name, so it obeys the member-name rule.
printf '\n=== --alias: refused cases ===\n'
arc() { "$@" >/dev/null 2>&1; echo $?; }
r1=$(arc "$LD" -o "$TMP/an1" --name BREXX --alias BREXX "$TMP/alt.o" -iebcopy)
r2=$(arc "$LD" -o "$TMP/an2" --name BREXX --alias RX1 --alias RX1 "$TMP/alt.o" -iebcopy)
r3=$(arc "$LD" --alias RX1 --pack "$TMP/altb.iebcopy" -o "$TMP/an3")
r4=$(arc "$LD" -o "$TMP/an4" --name BREXX --alias 9BAD "$TMP/alt.o" -iebcopy)
r5=$(arc "$LD" --pack "RX1=$TMP/altm.iebcopy" "BREXX=$TMP/altb.iebcopy" -o "$TMP/an5" -iebcopy)
if [ "$r1" != 0 ] && [ "$r2" != 0 ] && [ "$r3" != 0 ] && [ "$r4" != 0 ] && [ "$r5" != 0 ]; then
    echo "  OK: alias = member, alias twice, --alias with --pack, bad name, pack collision all refused"
else
    echo "  FAIL: a refusal passed (rc $r1 $r2 $r3 $r4 $r5)"; fails=$((fails + 1))
fi

# --map (cc370#9): a text load map, one line per section in origin order with
# the input it came from, entries beneath. The fixtures cover every kind of row:
# an explicit object with an entry, an unnamed private-code section with an
# entry, a member pulled by --include and one by autocall (with its own entry),
# an unresolved weak external, and the END-card entry. Four checks: the text itself; the
# member is byte-identical with and without --map; ORIGIN/LENGTH/entry
# addresses equal the produced member's CESD, read by file370 -- a second
# instrument, so the map is not checking itself; --map with --pack is refused.
printf '\n=== --map ===\n'
mapok=1
for m in mapmain mappc maplib mapinc; do
    "$AS" -o "$TMP/$m.o" "$FIX/$m.s" || { echo "  as370 failed: $m"; mapok=0; }
done
"$AR" rc "$TMP/libmap.a" "$TMP/maplib.o" "$TMP/mapinc.o" || { echo "  ar370 failed: map"; mapok=0; }
"$LD" -o "$TMP/mapm" --map "$TMP/mapm.map" -L"$TMP" -lmap --include mapinc "$TMP/mapmain.o" "$TMP/mappc.o" \
    || { echo "  ld370 --map failed"; mapok=0; }
"$LD" -o "$TMP/mapn" -L"$TMP" -lmap --include mapinc "$TMP/mapmain.o" "$TMP/mappc.o" \
    || { echo "  ld370 without --map failed"; mapok=0; }
cat > "$TMP/mapm.want" <<'MAPW'
LD370 MAP  MAPM  ENTRY 000000 (END card)  LENGTH 000030

SECTION   TYPE  ORIGIN  LENGTH  SOURCE
MAPMAIN   SD    000000  000010  @T@/mapmain.o
  MAPE1         000004
          PC    000010  000008  @T@/mappc.o
  MAPPCE        000014
MAPINC    SD    000018  00000C  @T@/libmap.a(mapinc.o) include
MAPLIB    SD    000028  000008  @T@/libmap.a(maplib.o) autocall
  MAPLIBE       00002C

UNRESOLVED
MAPWEAK   WX
MAPW
if [ $mapok = 1 ]; then
    sed "s#$TMP#@T@#g" "$TMP/mapm.map" | diff -u "$TMP/mapm.want" - || { echo "  FAIL: map text"; mapok=0; }
    cmp -s "$TMP/mapm" "$TMP/mapn" || { echo "  FAIL: --map changed the member"; mapok=0; }
    # every SECTION row and every entry row, against the CESD of the member itself
    "$FI" -v "$TMP/mapm" | python3 -c '
import re, sys
cesd = {}
for l in sys.stdin:
    m = re.match(r"\s+CESD\s+\d+\s+(\S+)\s+(SD|PC|LR)\s+addr=(\w+)(?:\s+len=(\w+))?", l)
    if m: cesd.setdefault((m.group(1), m.group(2)), []).append((m.group(3), m.group(4)))
rows = 0
for l in open(sys.argv[1]).read().split("\n\n")[1].splitlines()[1:]:
    if l.startswith("  ") and l[2] != " ":          # an entry row; a PC row is blank-named, not indented
        n, a = l.split(); key, want = (n, "LR"), (a, None)
    else:
        n = l[:8].strip() or "(blank)"; t, o, ln = l[10:].split()[:3]; key, want = (n, t), (o, ln)
    if want not in cesd.get(key, []): print("  FAIL: map row not in the CESD:", l); sys.exit(1)
    rows += 1
print("  map rows == CESD: %d" % rows)
' "$TMP/mapm.map" || mapok=0
    r=$(arc "$LD" --pack "A=$TMP/mapm" -o "$TMP/mapp" --map "$TMP/mapp.map")
    [ "$r" = 2 ] && [ ! -e "$TMP/mapp.map" ] || { echo "  FAIL: --map with --pack not refused (rc $r)"; mapok=0; }
fi
if [ $mapok = 1 ]; then echo "  OK: map text, member unchanged, rows == CESD, --pack refused"; else fails=$((fails + 1)); fi

# --xref (cc370#9, the XREF half): under each section, every address constant
# naming an external symbol, at its offset in the section, with where it
# resolved. The fixtures reach every kind of target: a section (V(MAPLIB)), an
# entry in a section (V(MAPLIBE), from the PC), an entry in an unnamed PC
# (A(MAPPCE)) and an unresolved weak external (A(MAPWEAK)). Checked against the
# text, and against the member by xref_check.py, which reads its RLD and adcons
# through lmdiff.parse -- not ld370 -- and fails on a wrong offset, address or
# target. --xref without --map is refused, and does not change the member.
printf '\n=== --map --xref ===\n'
xok=1
"$LD" -o "$TMP/mapx" --map "$TMP/mapx.map" --xref -L"$TMP" -lmap --include mapinc "$TMP/mapmain.o" "$TMP/mappc.o" \
    || { echo "  ld370 --xref failed"; xok=0; }
cat > "$TMP/mapx.want" <<'MAPW'
LD370 MAP  MAPX  ENTRY 000000 (END card)  LENGTH 000030

SECTION   TYPE  ORIGIN  LENGTH  SOURCE
  ENTRY         ADDRESS
  +OFFSET  CON  SYMBOL    ADDRESS  IN SECTION
MAPMAIN   SD    000000  000010  @T@/mapmain.o
  MAPE1         000004
  +000004  V    MAPLIB    000028  in MAPLIB
  +000008  A    MAPWEAK   unresolved (weak)
  +00000C  A    MAPPCE    000014  in PC 000010
          PC    000010  000008  @T@/mappc.o
  MAPPCE        000014
  +000004  V    MAPLIBE   00002C  in MAPLIB
MAPINC    SD    000018  00000C  @T@/libmap.a(mapinc.o) include
MAPLIB    SD    000028  000008  @T@/libmap.a(maplib.o) autocall
  MAPLIBE       00002C

UNRESOLVED
MAPWEAK   WX
MAPW
if [ $xok = 1 ]; then
    sed "s#$TMP#@T@#g" "$TMP/mapx.map" | diff -u "$TMP/mapx.want" - || { echo "  FAIL: xref text"; xok=0; }
    python3 ld370/tests/xref_check.py "$TMP/mapx" "$TMP/mapx.map" || xok=0
    cmp -s "$TMP/mapx" "$TMP/mapn" || { echo "  FAIL: --xref changed the member"; xok=0; }
    r=$(arc "$LD" -o "$TMP/mapy" --xref "$TMP/mapmain.o" -L"$TMP" -lmap)
    [ "$r" = 2 ] || { echo "  FAIL: --xref without --map not refused (rc $r)"; xok=0; }
fi
if [ $xok = 1 ]; then echo "  OK: xref text, rows == member RLD + adcons, member unchanged, needs --map"; else fails=$((fails + 1)); fi

# #519/#713: a missing input object ended the link at rc 1 with no message.
echo "== missing input object names itself (#519, #713)"
"$LD" -e MA -o "$TMP/missing.lm" "$TMP/no-such-object.o" 2>"$TMP/missing.err"; r=$?
if [ "$r" = 1 ] && grep -q "cannot open $TMP/no-such-object.o: " "$TMP/missing.err"; then
    echo "  OK: rc 1, '$(sed "s#$TMP/##" "$TMP/missing.err")'"
else
    echo "  FAIL: rc $r, stderr '$(cat "$TMP/missing.err")'"; fails=$((fails + 1))
fi

echo "== --entry seeds automatic library call (#107)"
# Nothing calls @@CRT0, so an entry living only in an archive was never pulled:
# `--entry symbol '@@CRT0' not found'.  Now it is autocalled by name, and what it
# references (@@START, here, and through it MAIN) joins the ordinary closure.
printf '@@CRT0   CSECT\n         USING *,15\n         L     15,=V(@@START)\n         BR    15\n         LTORG\n         END\n' > "$TMP/e107crt.s"
printf '@@START  CSECT\n         USING *,15\n         L     15,=V(MAIN)\n         BR    15\n         LTORG\n         END\n' > "$TMP/e107st.s"
printf 'MAIN     CSECT\n         SR    15,15\n         BR    14\n         END\n' > "$TMP/e107pg.s"
"$AS" "$TMP/e107crt.s" -o "$TMP/e107crt.o" && "$AS" "$TMP/e107st.s" -o "$TMP/e107st.o" && "$AS" "$TMP/e107pg.s" -o "$TMP/e107pg.o"
rm -f "$TMP/libe107.a"; "$AR" rc "$TMP/libe107.a" "$TMP/e107crt.o" "$TMP/e107st.o" >/dev/null
"$LD" -e @@CRT0 -o "$TMP/e107.lm" --name E107 "$TMP/e107pg.o" -L"$TMP" -le107 --map "$TMP/e107.map" 2>"$TMP/e107.err"; r=$?
if [ "$r" = 0 ] && grep -q '^LD370 MAP  E107  ENTRY @@CRT0 000008' "$TMP/e107.map" \
   && grep -q '^@@CRT0 .*libe107.a(e107crt.o) autocall' "$TMP/e107.map" \
   && grep -q '^@@START .*libe107.a(e107st.o) autocall' "$TMP/e107.map"; then
    echo "  OK: @@CRT0 and, through it, @@START pulled from the archive; entry 000008"
else
    echo "  FAIL: rc $r, $(cat "$TMP/e107.err")"; cat "$TMP/e107.map" 2>/dev/null; fails=$((fails + 1))
fi
# named explicitly, the entry object is not looked up in the archive at all
"$LD" -e @@CRT0 -o "$TMP/e107x.lm" --name E107 "$TMP/e107crt.o" "$TMP/e107pg.o" -L"$TMP" -le107 --map "$TMP/e107x.map"; r=$?
if [ "$r" = 0 ] && grep -q "^@@CRT0 .*e107crt.o\$" "$TMP/e107x.map"; then
    echo "  OK: an explicit entry object is used as given"
else
    echo "  FAIL: rc $r, explicit @@CRT0 not taken from the command line"; fails=$((fails + 1))
fi
# and an entry nothing defines fails as it always did
"$LD" -e NOSUCH -o "$TMP/e107n.lm" "$TMP/e107pg.o" -L"$TMP" -le107 2>"$TMP/e107n.err"; r=$?
if [ "$r" = 1 ] && grep -q "^ld370: --entry symbol 'NOSUCH' not found or unresolved\$" "$TMP/e107n.err"; then
    echo "  OK: an undefined entry is still rc 1 with the old message"
else
    echo "  FAIL: rc $r, '$(cat "$TMP/e107n.err")'"; fails=$((fails + 1))
fi
rm -f "$TMP"/e107* "$TMP/libe107.a"

echo "== a duplicate CSECT: the first definition is kept, as IEWL does (#102)"
# The objects of tests/run_iewl_dupcsect_oracle.py, and IEWL's own answer for
# them (MVSCE-LAB JOB01409): OB defines QQ again, in the middle of the object.
# IEWL drops the later QQ -- text, space, the RLDs inside it, its ENTRY QE --
# compacts OC up behind OB, and binds every reference to the first QQ.
# ld370 used to keep the LAST copy and both copies' text.
printf 'OA       CSECT\n         DC    A(QQ)\n         DC    A(OA)\nQQ       CSECT\n         DC    CL4%sQQ1%s\n         END\n' "'" "'" > "$TMP/d102a.s"
printf 'OB       CSECT\n         DC    A(QQ)\n         DC    A(OC)\nQQ       CSECT\n         ENTRY QE\n         DC    A(OB)\n         DC    A(QQ)\nQE       DC    CL8%sQQ2%s\n         DC    4F%s0%s\nOC       CSECT\n         DC    CL4%sOC%s\n         DC    A(QE)\n         END\n' "'" "'" "'" "'" "'" "'" > "$TMP/d102b.s"
printf 'OD       CSECT\n         DC    V(QE)\n         DC    V(OC)\n         END\n' > "$TMP/d102d.s"
for x in a b d; do "$AS" "$TMP/d102$x.s" -o "$TMP/d102$x.o" || echo "  assemble d102$x failed"; done
d102words() {   # the module's text as offset:word pairs
    python3 - "$1" "$FI" <<'PY'
import sys, subprocess, re
v = subprocess.run([sys.argv[2], "-v", sys.argv[1]], capture_output=True, text=True).stdout
off, n = [(int(a, 16), int(b)) for a, b in re.findall(r"@([0-9A-F]+)\s+text\s+(\d+) bytes", v)][0]
d = open(sys.argv[1], "rb").read()[off:off + n]
print(" ".join("%02X:%08X" % (a, int.from_bytes(d[a:a + 4], "big")) for a in range(0, n, 4)))
PY
}
# TE: OA, OB, OD.  QE goes with the dropped QQ, so OD's V(QE) is unresolved.
"$LD" -o "$TMP/d102te.lm" --name TE "$TMP/d102a.o" "$TMP/d102b.o" "$TMP/d102d.o" \
      --allow-unresolved --map "$TMP/d102te.map" 2>"$TMP/d102te.err"; r=$?
want="OA:000000:000008 QQ:000008:000004 OB:000010:000008 OC:000018:000008 OD:000020:000008"
got=$(awk '$2=="SD"{printf "%s%s:%s:%s", s, $1, $3, $4; s=" "}' "$TMP/d102te.map")
w=$(d102words "$TMP/d102te.lm")
if [ "$r" = 0 ] && [ "$got" = "$want" ] && grep -q 'LENGTH 000028' "$TMP/d102te.map" \
   && echo "$w" | grep -q '10:00000008 14:00000018 18:D6C34040 1C:00000010 20:00000000' \
   && grep -q 'adcon at 00001C points +8 bytes into CSECT .QQ.' "$TMP/d102te.err" \
   && [ "$(grep -c 'warning: adcon' "$TMP/d102te.err")" = 1 ]; then
    echo "  OK: TE = IEWL's layout (x28); OB's A(QQ)=08, OC's A(QE)=10 and warned, V(QE) unresolved"
else
    echo "  FAIL: TE rc $r layout '$got' text '$w'"; cat "$TMP/d102te.err"; fails=$((fails + 1))
fi
# TE2: OB, OA, OD.  Now OA's QQ, at the end of its object, is the one dropped.
"$LD" -o "$TMP/d102t2.lm" --name TE2 "$TMP/d102b.o" "$TMP/d102a.o" "$TMP/d102d.o" \
      --map "$TMP/d102t2.map" 2>"$TMP/d102t2.err"; r=$?
want="OB:000000:000008 QQ:000008:000020 OC:000028:000008 OA:000030:000008 OD:000038:000008"
got=$(awk '$2=="SD"{printf "%s%s:%s:%s", s, $1, $3, $4; s=" "}' "$TMP/d102t2.map")
w=$(d102words "$TMP/d102t2.lm")
if [ "$r" = 0 ] && [ "$got" = "$want" ] && grep -q 'LENGTH 000040' "$TMP/d102t2.map" \
   && echo "$w" | grep -q '30:00000008 34:00000030 38:00000010 3C:00000028' \
   && ! grep -q 'warning' "$TMP/d102t2.err" \
   && [ "$(grep -c 'note: CSECT QQ defined again' "$TMP/d102t2.err")" = 1 ]; then
    echo "  OK: TE2 = IEWL's layout (x40); OA's A(QQ)=08, OD's V(QE)=10; rc 0, one note for the dropped QQ (#807)"
else
    echo "  FAIL: TE2 rc $r layout '$got' text '$w'"; cat "$TMP/d102t2.err"; fails=$((fails + 1))
fi
rm -f "$TMP"/d102*

echo "== an entry defined by two explicit objects is warned about, first kept (#478)"
# IEWL, MVSCE-LAB JOB01639: EA and EB both define ENTRY DUPE, EC refers to it.
# IEW0241 DOUBLY DEFINED, RC 4, in both orders; the first definition is kept
# and EC's V(DUPE) binds to it -- EA+4, or EB+8 with the order swapped.
# ld370 bound the same way and said nothing (except for an autocalled member).
printf "EA       CSECT\n         ENTRY DUPE\n         DC    CL4'EA1'\nDUPE     DC    CL4'EA2'\n         END\n" > "$TMP/d478a.s"
printf "EB       CSECT\n         ENTRY DUPE\n         DC    CL8'EB1'\nDUPE     DC    CL4'EB2'\n         END\n" > "$TMP/d478b.s"
printf "EC       CSECT\n         DC    V(DUPE)\n         END\n" > "$TMP/d478c.s"
for x in a b c; do "$AS" "$TMP/d478$x.s" -o "$TMP/d478$x.o" || echo "  assemble d478$x failed"; done
for ord in ab ba; do
    if [ $ord = ab ]; then o1=a; o2=b; want=00000004; else o1=b; o2=a; want=00000008; fi
    "$LD" -o "$TMP/d478$ord.lm" --name T "$TMP/d478$o1.o" "$TMP/d478$o2.o" "$TMP/d478c.o" 2>"$TMP/d478$ord.err"; r=$?
    got=$(python3 - "$TMP/d478$ord.lm" "$FI" <<'PY'
import sys, subprocess, re
v = subprocess.run([sys.argv[2], "-v", sys.argv[1]], capture_output=True, text=True).stdout
off, n = [(int(a, 16), int(b)) for a, b in re.findall(r"@([0-9A-F]+)\s+text\s+(\d+) bytes", v)][0]
print(open(sys.argv[1], "rb").read()[off + 0x18:off + 0x1C].hex().upper())
PY
)
    if [ "$r" = 0 ] && [ "$got" = "$want" ] \
       && grep -q "warning: 'DUPE' doubly defined: .*d478$o2.o defines it again (first definition kept)" "$TMP/d478$ord.err"; then
        echo "  OK: order $o1,$o2: warned, V(DUPE) = $want (the first definition), as IEWL"
    else
        echo "  FAIL: order $o1,$o2: rc $r, V(DUPE) $got (want $want), stderr '$(cat "$TMP/d478$ord.err")'"; fails=$((fails + 1))
    fi
done
rm -f "$TMP"/d478*

# --- #807: the Command Reference findings ---------------------------------
# Each check fails on 1.2.0.
printf '\n=== #807: options, inputs, names, --ac, --blocksize, --pack, trace ===\n'
printf 'S807     CSECT\n         ENTRY E807\nE807     BR    14\n         END   S807\n' > "$TMP/s807.s"
"$AS" -o "$TMP/s807.o" "$TMP/s807.s" 2>/dev/null
c807() {   # NAME WANT-RC GREP-ERE ARGS...   -- rc and a stderr pattern
    nm=$1; want=$2; pat=$3; shift 3
    "$LD" "$@" >"$TMP/c807.out" 2>"$TMP/c807.err"; r=$?
    if [ "$r" = "$want" ] && { [ -z "$pat" ] || grep -qE -e "$pat" "$TMP/c807.err" "$TMP/c807.out"; }; then
        echo "  OK: $nm (rc $r)"
    else
        echo "  FAIL: $nm: rc $r (want $want), $(head -1 "$TMP/c807.err")"; fails=$((fails + 1))
    fi
}
c807 "--help prints the usage"                 0 "usage: ld370"            --help
c807 "an unknown option is refused"            2 "unknown option '--bogus'" --bogus -o "$TMP/x" "$TMP/s807.o"
c807 "-e given last needs a value"             2 "-e needs a value"         -o "$TMP/x" "$TMP/s807.o" -e
printf 'int main(void){return 0;}\n' > "$TMP/hello807.c"; rm -f "$TMP/T807"
c807 "a C source is not an object"             1 "not an object deck"       -o "$TMP/T807" "$TMP/hello807.c"
[ -e "$TMP/T807" ] && { echo "  FAIL: a member was written for hello.c"; fails=$((fails + 1)); }
c807 "--name 1BAD is refused with -iebcopy"    2 "'1BAD' \(--name\) is not a valid" --name 1BAD -iebcopy -o "$TMP/x" "$TMP/s807.o"
c807 "a 12-char -o name is refused with -xmit" 2 "from -o\) is not a valid.*give --name" -xmit -o "$TMP/verylongname" "$TMP/s807.o"
c807 "a bare -o member needs no MVS name"      0 ""                         -o "$TMP/very_long_name" "$TMP/s807.o"
c807 "--ac 300 is out of range"                2 "--ac 300 out of range"    --ac 300 -o "$TMP/x" "$TMP/s807.o"
c807 "--blocksize abc is not a number"         2 "--blocksize takes a number, not 'abc'" --blocksize abc -o "$TMP/x" "$TMP/s807.o"
"$LD" -o "$TMP/P807" --name P807 -e E807 "$TMP/s807.o" -xmit 2>/dev/null
c807 "--pack of an XMIT names the format"      2 "is a TSO transmission"    --pack "$TMP/P807.xmit" -o "$TMP/q"
c807 "--pack of an object deck names it"       2 "is an object deck"        --pack "$TMP/s807.o" -o "$TMP/q"
c807 "--name with --pack is refused"           2 "NAME=FILE"                --pack --name X "$TMP/P807" -o "$TMP/q"
c807 "--sparse-text with --pack is warned"     0 "--sparse-text is ignored by --pack" --pack --sparse-text P807="$TMP/P807" -o "$TMP/q"
"$LD" -v -o "$TMP/x" -e E807 "$TMP/s807.o" 2>&1 | grep -qE "1 section\(s\) \+ 1 LR \+ 0 ER" \
    && echo "  OK: -v counts the LR as an LR, not an ER" \
    || { echo "  FAIL: -v trace: $("$LD" -v -o "$TMP/x" -e E807 "$TMP/s807.o" 2>&1 | grep 'CESD:')"; fails=$((fails + 1)); }
rm -f "$TMP"/s807.* "$TMP"/c807.* "$TMP"/hello807.c "$TMP"/P807* "$TMP"/q* "$TMP"/x "$TMP"/very_long_name "$TMP"/T807

printf '\n'
if [ "$fails" -eq 0 ]; then
    echo "ld370 regression: ALL GREEN"
else
    echo "ld370 regression: $fails FAILED"
fi
exit "$fails"
