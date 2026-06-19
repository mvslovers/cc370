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
# sample8 (tinitvl, WTO) and sample9 (irxtmpw, XCTL->IHBINNRB) are real rexx370
# modules that exercise the hardest macro paths — they guard against regressing
# the byte-exact REXX corpus when changing the assembler for other projects.
# sample10 is the multiple-distinct-CSECT case (two text-producing sections in
# one assembly): origins stack, each section keeps its own ESD length, and each
# section's TXT card carries its own ESDID.
fail=0
for s in sample1 sample2 sample3 sample4 sample5 sample6 sample7 sample8 sample9 sample10; do
    ./as370 "tests/$s.s" $MACLIB -o "/tmp/$s.obj" >/dev/null 2>&1 || { echo "$s: ASSEMBLE FAILED"; fail=1; continue; }
    ref="tests/ref/$s.obj"
    mysz=$(wc -c < "/tmp/$s.obj"); refsz=$(wc -c < "$ref")
    # both decks end in a single END card (differs only in the optional IDR);
    # require equal deck size so a spurious/missing trailing card is caught, then
    # compare every card before END byte-for-byte.
    if [ "$mysz" != "$refsz" ]; then echo "$s: MISMATCH (deck $mysz vs $refsz bytes)"; fail=1; continue; fi
    nbe=$(( (refsz / 80 - 1) * 80 ))
    head -c "$nbe" "/tmp/$s.obj" > /tmp/_a.$$; head -c "$nbe" "$ref" > /tmp/_b.$$
    if cmp -s /tmp/_a.$$ /tmp/_b.$$; then echo "$s: OK (== IFOX00)"; else echo "$s: MISMATCH"; fail=1; fi
done
rm -f /tmp/_a.$$ /tmp/_b.$$
[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
