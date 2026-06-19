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
    "$LD" -o "$TMP/$name.ld.bin" $objs || { echo "ld370 failed: $name"; fails=$((fails + 1)); return; }
    printf '\n=== %s  (oracle %s) ===\n' "$name" "$oracle"
    $DIFF diff "$FIX/$oracle" "$TMP/$name.ld.bin" || fails=$((fails + 1))
}

run_case tiny  tiny1.bin tiny.s
run_case rldt  rldt.bin  rldt.s
run_case modab modab.bin mod_a.s mod_b.s

# Known-blocked (needs the as370 multiple-distinct-CSECT fix): twosec.s
# Re-enable once as370 emits correct multi-section objects:
#   run_case twosec twosec.bin twosec.s

printf '\n'
if [ "$fails" -eq 0 ]; then
    echo "ld370 regression: ALL GREEN"
else
    echo "ld370 regression: $fails FAILED"
fi
exit "$fails"
