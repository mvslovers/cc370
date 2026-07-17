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

# --- issue #12: RS/SI/S empty-index operand rejection -----------------------
# D2(,B2) (or D2(X2,B2)) on an RS/SI/S storage operand has no index field;
# IFOX00 rejects it (ERR216, severity 12). as370 must reject it too rather than
# silently emit base 0. The correct D(B) form -- and the RX D(,B) form, which
# DOES have an index field -- must still assemble.
if ./as370 tests/rs_badidx.s -o /tmp/_rsbad.obj >/tmp/_rsbad.out 2>&1; then
    echo "rs_badidx: NOT REJECTED (expected RC 12)"; fail=1
elif ! grep -q "Illegal operand format" /tmp/_rsbad.out; then
    echo "rs_badidx: rejected but no diagnostic emitted"; fail=1
else
    echo "rs_badidx: OK (rejected -- RS D(,B) flagged)"
fi
if ./as370 tests/rs_goodidx.s -o /tmp/_rsgood.obj >/dev/null 2>&1 &&
   od -An -tx1 /tmp/_rsgood.obj | tr -d ' \n' | grep -q '980cd014' &&
   od -An -tx1 /tmp/_rsgood.obj | tr -d ' \n' | grep -q '58e0d00c'; then
    echo "rs_goodidx: OK (RS D(B)=980CD014, RX D(,B)=58E0D00C)"
else
    echo "rs_goodidx: FAIL (valid RS/RX operands must assemble)"; fail=1
fi
rm -f /tmp/_rsbad.obj /tmp/_rsbad.out /tmp/_rsgood.obj

# --- issue #18: relocatable displacement with an explicit base --------------
# SYM(Rn) where SYM is relocatable (a DSECT/section symbol) and Rn is explicit
# is an addressability error: IFOX00 rejects it (IFO228, severity 8) and
# assembles the whole instruction as zero. Only the implicit form SYM(len) --
# where the assembler picks the base from a USING -- may be relocatable.
# as370 used to emit SYM - <active USING base>, a silently wrong displacement.
# reloc_disp.s exercises the shape in all five operand formats that carry a
# storage operand (RX/RS/SI/SS and the 2-byte-opcode S format STCK/SPKA); its
# expected bytes were pinned against real IFOX00 on MVS 3.8j (IFOXTST/JOB00229).
# as370 must reject (RC 8) and zero each flagged instruction, while the four
# legal forms stay byte-identical:
#   LA  1,LAB(2)            implicit D(X), base from USING   -> 4112 C02E
#   STCK LAB               implicit S, base from USING       -> B205 C02E
#   MVC LAB(8),0(3)         implicit length, base from USING -> D207 C02E 3000
#   MVC FLD-MYDS(8,2),0(3)  absolute difference              -> D207 2028 3000
# The object deck concatenates the six flagged instructions zeroed (RX/RS/SI 4B,
# SS 6B, STCK/SPKA 4B), then the four legal instructions above.
if ./as370 tests/reloc_disp.s -o /tmp/_reld.obj >/tmp/_reld.out 2>&1; then
    echo "reloc_disp: NOT REJECTED (expected RC 8)"; fail=1
elif [ $? -ne 8 ]; then
    echo "reloc_disp: rejected but RC != 8"; fail=1
elif [ "$(grep -c 'Relocatable displacement in machine instruction' /tmp/_reld.out)" != 6 ]; then
    echo "reloc_disp: expected 6 IFO228 diagnostics (RX/RS/SI/SS/STCK/SPKA), got $(grep -c 'Relocatable displacement' /tmp/_reld.out)"; fail=1
else
    txt=$(od -An -tx1 /tmp/_reld.obj | tr -d ' \n')
    # the six flagged instructions zeroed (RX/RS/SI 4B + SS 6B + STCK/SPKA 4B =
    # 26 bytes = 52 hex zeros), in order, followed by the four legal forms
    want="$(printf '%052d' 0)4112c02eb205c02ed207c02e3000d20720283000"
    if echo "$txt" | grep -q "$want"; then
        echo "reloc_disp: OK (RX/RS/SI/SS/S IFO228 zeroed; legal LA/STCK/MVC forms byte-identical to IFOX00)"
    else
        echo "reloc_disp: FAIL (object deck not byte-identical to IFOX00)"
        echo "  want ...$want"; echo "  got  $txt"; fail=1
    fi
fi
rm -f /tmp/_reld.obj /tmp/_reld.out

[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
