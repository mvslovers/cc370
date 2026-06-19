#!/bin/sh
# ld370 regression: build the toolchain, link each case with the host-native
# chain (as370 per source -> ld370 over all the objects), and byte-diff the
# result against the IEWL oracle via the record-aware differ. Non-zero on any
# mismatch.
#
# The diff is carve-out-aware: the IDR identity records (LKED/translator)
# legitimately differ (ld stamps its own identity) and are skipped; the
# byte-exact target is CESD + SPZAP-IDR + control + text + RLD.
cd "$(dirname "$0")/../.." || exit 2          # repo root (c2asm370)

AS=./as/as370
LD=./ld/ld370
DIFF="python3 ld/tests/lmdiff.py"
FIX=ld/tests/fixtures
TMP="${TMPDIR:-/tmp}"

[ -x "$AS" ] || gcc -O2 -Wall -Wextra -Werror -o "$AS" as/as370.c || exit 2
gcc -O2 -Wall -Wextra -Werror -o "$LD" ld/ld370.c || exit 2

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
    # shellcheck disable=SC2086
    "$LD" -o "$TMP/$name.ld.bin" --unload "$TMP/$name.unl" --name "$name" $objs \
        || { echo "ld370 failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== %s  (oracle %s) ===\n' "$name" "$oracle"
    $DIFF diff "$FIX/$oracle" "$TMP/$name.ld.bin" || fails=$((fails + 1))
    # round-trip: the --unload image must reconstruct the member just linked.
    # Guards split_member on the control/RLD path real modules take (e2e is
    # RLD-free, so this is the only host-side check of the 0x0E branch).
    NM=$(printf '%s' "$name" | tr 'a-z' 'A-Z')   # member_name() upper-cases
    python3 ld/tests/unload_check.py "$TMP/$name.unl" "$NM=$TMP/$name.ld.bin" \
        || fails=$((fails + 1))
}

run_case tiny  tiny1.bin tiny.s
run_case rldt  rldt.bin  rldt.s
run_case modab  modab.bin  mod_a.s mod_b.s
run_case twosec twosec.bin twosec.s     # two distinct CSECTs in one object
run_case klein  klein.bin  klein.s      # ENTRY/LD (-> composite LR) + RLD SAMERP continuation

# IEBCOPY unloaded-image emitter: wrap a known IEWL member and byte-diff against
# the IEBCOPY UNLOAD oracle.  NOTE: a green diff proves only that the member
# WRAPPING is correct -- the COPYR1/COPYR2 environment header is echoed from this
# same oracle, so it cannot regress.  It does NOT prove the image reloads on MVS;
# the real oracle is IEBCOPY LOAD + run (Stage 2).
run_unload() {
    name=$1; member=$2; oracle=$3; mname=$4
    "$LD" --unload-from "$FIX/$member" --name "$mname" --unload "$TMP/$name.unload" \
        || { echo "ld370 --unload failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== unload %s  (oracle %s) ===\n' "$name" "$oracle"
    if cmp -s "$FIX/$oracle" "$TMP/$name.unload"; then
        echo "unload: BYTE-IDENTICAL"
    else
        echo "unload: DIFFERS"; cmp "$FIX/$oracle" "$TMP/$name.unload"; fails=$((fails + 1))
    fi
}

run_unload e2e e2e.iewl-member.bin e2e.iebcopy-unload.bin E2E

# multi-member: pack two linked members into one image (deliberately in
# non-sorted input order) and confirm both reconstruct + the directory is
# name-sorted.  No byte oracle -- structural round-trip only (single track).
printf '\n=== pack tiny+rldt (multi-member) ===\n'
if "$LD" --pack TINY="$TMP/tiny.ld.bin" --pack RLDT="$TMP/rldt.ld.bin" \
        --unload "$TMP/lib2.unl" 2>/dev/null; then
    python3 ld/tests/unload_check.py "$TMP/lib2.unl" \
        "TINY=$TMP/tiny.ld.bin" "RLDT=$TMP/rldt.ld.bin" || fails=$((fails + 1))
else
    echo "ld370 --pack failed"; fails=$((fails + 1))
fi

printf '\n'
if [ "$fails" -eq 0 ]; then
    echo "ld370 regression: ALL GREEN"
else
    echo "ld370 regression: $fails FAILED"
fi
exit "$fails"
