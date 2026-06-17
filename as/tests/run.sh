#!/bin/sh
# Assemble each sample and verify the object deck (all cards before the END
# card, which legitimately differs only in the IDR) is byte-identical to the
# IFOX00 reference in tests/ref/.
cd "$(dirname "$0")/.." || exit 2
# Macro libraries: crent370/maclib (crent370's own PDP macros) and
# crent370/sysmac (host-only mirror of the SYS1.MACLIB members the build needs:
# SAVE/RETURN/IHBERMAC, SVC macros). Override the repo root with CRENT=... .
CRENT=${CRENT:-../../crent370}
MACLIB="-I $CRENT/maclib -I $CRENT/sysmac"
fail=0
for s in sample1 sample2 sample3 sample4 sample5 sample6 sample7; do
    ./as370 "tests/$s.s" $MACLIB -o "/tmp/$s.obj" >/dev/null 2>&1 || { echo "$s: ASSEMBLE FAILED"; fail=1; continue; }
    ref="tests/ref/$s.obj"
    nbe=$(( ($(wc -c < "$ref") / 80 - 1) * 80 ))
    head -c "$nbe" "/tmp/$s.obj" > /tmp/_a.$$; head -c "$nbe" "$ref" > /tmp/_b.$$
    if cmp -s /tmp/_a.$$ /tmp/_b.$$; then echo "$s: OK (== IFOX00)"; else echo "$s: MISMATCH"; fail=1; fi
done
rm -f /tmp/_a.$$ /tmp/_b.$$
[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
