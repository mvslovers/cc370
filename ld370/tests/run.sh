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
    "$LD" -o "$TMP/$name.ld.bin" --unload --name "$name" --allow-unresolved $objs \
        || { echo "ld370 failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== %s  (oracle %s) ===\n' "$name" "$oracle"
    $DIFF diff "$FIX/$oracle" "$TMP/$name.ld.bin" || fails=$((fails + 1))
    # round-trip: the --unload image must reconstruct the member just linked.
    # Guards split_member on the control/RLD path real modules take (e2e is
    # RLD-free, so this is the only host-side check of the 0x0E branch).
    NM=$(printf '%s' "$name" | tr 'a-z' 'A-Z')   # member_name() upper-cases
    python3 ld370/tests/unload_check.py "$TMP/$name.ld.bin.unl" "$NM=$TMP/$name.ld.bin" \
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
    "$LD" --unload-from "$FIX/$member" --name "$mname" -o "$TMP/$name" --unload \
        || { echo "ld370 --unload failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== unload %s ===\n' "$name"
    python3 ld370/tests/unload_check.py "$TMP/$name.unl" "$mname=$FIX/$member" \
        || fails=$((fails + 1))
}

run_unload e2e e2e.iewl-member.bin E2E

# XMIT (TSO TRANSMIT / NETDATA) wrapper: wrap the e2e member's unload and check
# FB80 + the INMR control set + that the data records carry the unload payload
# byte-faithfully.  Validated end-to-end on MVS: the FB80 upload RECV370-installs
# (IEB154I) and the member runs (RC=7) through the multi-track emitter.
printf '\n=== xmit e2e ===\n'
if "$LD" --unload-from "$FIX/e2e.iewl-member.bin" --name E2E --dsn IBMUSER.E2E.LOAD \
        -o "$TMP/e2e" --unload --xmit 2>/dev/null; then
    python3 ld370/tests/xmit_check.py "$TMP/e2e.xmit" "$TMP/e2e.unl" \
        || fails=$((fails + 1))
else
    echo "ld370 --xmit failed"; fails=$((fails + 1))
fi

# multi-member: pack two linked members into one image (deliberately in
# non-sorted input order) and confirm both reconstruct + the directory is
# name-sorted.  No byte oracle -- structural round-trip only (single track).
printf '\n=== pack tiny+rldt (multi-member) ===\n'
if "$LD" --pack TINY="$TMP/tiny.ld.bin" --pack RLDT="$TMP/rldt.ld.bin" \
        -o "$TMP/lib2" --unload 2>/dev/null; then
    python3 ld370/tests/unload_check.py "$TMP/lib2.unl" \
        "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" || fails=$((fails + 1))
else
    echo "ld370 --pack failed"; fails=$((fails + 1))
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

printf '\n'
if [ "$fails" -eq 0 ]; then
    echo "ld370 regression: ALL GREEN"
else
    echo "ld370 regression: $fails FAILED"
fi
exit "$fails"
