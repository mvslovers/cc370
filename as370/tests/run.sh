#!/bin/sh
# Assemble each sample and verify the object deck (all cards before the END
# card, which legitimately differs only in the IDR) is byte-identical to the
# IFOX00 reference in tests/ref/.
cd "$(dirname "$0")/.." || exit 2
# Macro libraries: maclib (the PDP macros -- PDPTOP/PDPPRLG/PDPEPIL) and sysmac
# (host-only mirror of the SYS1.MACLIB members the build needs: SAVE/RETURN/
# IHBERMAC, SVC macros). These now live in libc370; the default used to point at
# crent370, the frozen v1.x libc, which no longer needs to be checked out -- so
# the suite failed with "Undefined operation code ... PDPPRLG" wherever it was
# absent. Override the repo root with CRENT=... .
CRENT=${CRENT:-../../libc370}
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

# --- issue #21: relocatable implicit-base operand with no covering USING ------
# A relocatable operand addressed implicitly (base chosen from a USING) resolves
# iff its own section has a USING in range, else IFO209 (severity 8, instruction
# zeroed, ADDR 0). as370 used to resolve it through a cross-section USING (:361)
# or emit base 0 (:363). reloc_addr.s pins this against real IFOX00 (JOB00233):
#   reject -> IFO209 zeroed: 1 LABX(:363) 2 =F'7'(literal) 5 FLDX(:361) 6 FLDX+8-8
#   resolve (unchanged):     3 LABX+4-4  4 =F'9'  7 FLDX+8-8 via r13  8 FLDX via r13
# Instructions in source order (RX, 4 bytes): zeroed,zeroed,5810C020,5810C02C,
# zeroed,zeroed,5810D028,5810D028.
RA_CODE=00000000000000005810c0205810c02c00000000000000005810d0285810d028
if ./as370 tests/reloc_addr.s -o /tmp/_ra.obj >/tmp/_ra.out 2>&1; then
    echo "reloc_addr: NOT REJECTED (expected RC 8)"; fail=1
elif [ $? -ne 8 ]; then
    echo "reloc_addr: rejected but RC != 8"; fail=1
elif [ "$(grep -c 'Addressability error' /tmp/_ra.out)" != 4 ]; then
    echo "reloc_addr: expected 4 IFO209 diagnostics, got $(grep -c 'Addressability error' /tmp/_ra.out)"; fail=1
elif ! od -An -tx1 /tmp/_ra.obj | tr -d ' \n' | grep -q "$RA_CODE"; then
    echo "reloc_addr: FAIL object deck differs from IFOX00"; fail=1
else
    echo "reloc_addr: OK (IFO209 rejected + zeroed; resolves byte-identical to IFOX00)"
fi
# case-(b) tripwire, shown explicitly: stmt 7 (FLDX+8-8 via r13) is the SAME
# operand as stmt 6 but addressable only because r13->MYDS is active. It must
# RESOLVE to 5810 D028; a flip to IFO209 means expr_sect and the USING section
# disagree on a same-section compound -- the fix is wrong, not the test.
if od -An -tx1 /tmp/_ra.obj 2>/dev/null | tr -d ' \n' | grep -q '5810d028'; then
    echo "reloc_addr: OK stmt7 case-(b) tripwire  FLDX+8-8 via r13 = 5810 D028  RESOLVES"
else
    echo "reloc_addr: FAIL stmt7 case-(b) tripwire flipped -- same-section compound rejected"; fail=1
fi
rm -f /tmp/_ra.obj /tmp/_ra.out

# --- issue #20: over-length symbol diagnosed, not silently truncated ---------
# A symbol longer than 8 characters exceeds the MVS object-deck (ESD) name
# limit. as370 used to store it truncated on insert while comparing the full
# name on lookup, so two distinct names sharing their first 8 characters
# (PREFIXAB1/PREFIXAB2 -> PREFIXAB) both landed on one ESD entry with no
# diagnostic (rc=0) -- a silent mislinkage. IFOX00 rejects an over-length symbol
# (ERR187, severity 8); as370 must too. overlong_sym.s is the issue reproducer
# (two ENTRY names colliding on their first 8 chars); expect RC 8 and one ERR187
# per distinct over-length ENTRY operand (2). NB: the two DC labels (PREFIXAB1/
# PREFIXAB2) are ALSO over-length name fields and are separately flagged by the
# #32 name-field diagnostic, so match ERR187's own message, not the shared
# "Symbol longer than 8 characters" prefix.
if ./as370 tests/overlong_sym.s -o /tmp/_ovl.obj >/tmp/_ovl.out 2>&1; then
    echo "overlong_sym: NOT REJECTED (expected RC 8)"; fail=1
elif [ $? -ne 8 ]; then
    echo "overlong_sym: rejected but RC != 8"; fail=1
elif [ "$(grep -c 'MVS external names are limited to 8' /tmp/_ovl.out)" != 2 ]; then
    echo "overlong_sym: expected 2 ERR187 (external) diagnostics, got $(grep -c 'MVS external names are limited to 8' /tmp/_ovl.out)"; fail=1
else
    echo "overlong_sym: OK (over-length ENTRY names flagged ERR187, not silently truncated)"
fi
rm -f /tmp/_ovl.obj /tmp/_ovl.out
# boundary control: an exactly-8-char external name must still assemble clean.
printf 'OK8TEST  CSECT\n         ENTRY PREFIXAB\nPREFIXAB DC     F%s1%s\n         END\n' "'" "'" > /tmp/_ok8.s
if ./as370 /tmp/_ok8.s -o /tmp/_ok8.obj >/dev/null 2>&1; then
    echo "overlong_sym: OK (8-char name PREFIXAB assembles clean -- no over-rejection)"
else
    echo "overlong_sym: FAIL (8-char name wrongly rejected)"; fail=1
fi
rm -f /tmp/_ok8.s /tmp/_ok8.obj

# --- issue #32: over-length ORDINARY symbol (local label / EQU name) ----------
# An ordinary symbol >8 chars is REJECTED by IFOX00, not truncated -- and via a
# different path than the ENTRY/EXTRN external (#20, ERR187): the NAME FIELD is
# illegal (IFO016, sev 8; symbol NOT entered, but storage still reserved) and an
# over-length symbol TERM in an operand is illegal (IFO236, sev 8; the whole
# instruction is zeroed -- IFOX does NOT truncate a reference to resolve it).
# Pinned against real IFOX00 (JOB00256, RC=8). PRE-FIX as370 assembled this RC=0
# and emitted a valid opcode over base/displacement 0 (L 1,LONGLABEL9 -> 5810
# 0000, a silent load from address 0); POST-FIX it must reject (RC 8) with 3
# name-field + 4 operand diagnostics, zeroing each flagged instruction, while
# the 8-char control L 2,EIGHTCHR stays 5820 F000.
if ./as370 tests/overlong_ordinary.s -o /tmp/_o32.obj >/tmp/_o32.out 2>&1; then
    echo "overlong_ordinary: NOT REJECTED (expected RC 8)"; fail=1
elif [ $? -ne 8 ]; then
    echo "overlong_ordinary: rejected but RC != 8"; fail=1
elif [ "$(grep -c 'in name field' /tmp/_o32.out)" != 3 ]; then
    echo "overlong_ordinary: expected 3 name-field (IFO016) diagnostics, got $(grep -c 'in name field' /tmp/_o32.out)"; fail=1
elif [ "$(grep -c 'in operand expression' /tmp/_o32.out)" != 4 ]; then
    echo "overlong_ordinary: expected 4 operand (IFO236) diagnostics, got $(grep -c 'in operand expression' /tmp/_o32.out)"; fail=1
else
    hex=$(od -An -tx1 /tmp/_o32.obj | tr -d ' \n')
    # the five instructions at offset 0x0C, in order: L 1,LONGLABEL9 (zeroed),
    # L 2,EIGHTCHR (resolves 5820F000), L 3,NINECHAR9 (zeroed), LA 4,BIGEQUNAME
    # (zeroed), L 5,EIGHTCHRX (zeroed).
    want=000000005820f000000000000000000000000000
    if echo "$hex" | grep -q "$want"; then
        echo "overlong_ordinary: OK (IFO016 name-field abandoned + IFO236 operand zeroed; 8-char control resolves, byte-pinned to IFOX00)"
    else
        echo "overlong_ordinary: FAIL (object bytes not as pinned to IFOX00)"; echo "  want ...$want"; echo "  got  $hex"; fail=1
    fi
fi
rm -f /tmp/_o32.obj /tmp/_o32.out

[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
