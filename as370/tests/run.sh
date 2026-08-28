#!/bin/sh
# Assemble each sample and verify the object deck (all cards before the END
# card, which legitimately differs only in the IDR) is byte-identical to the
# IFOX00 reference in tests/ref/.
cd "$(dirname "$0")/.." || exit 2
# Macro libraries: maclib (the PDP macros -- PDPTOP/PDPPRLG/PDPEPIL) and sysmac
# (host-only mirror of the SYS1.MACLIB members the build needs: SAVE/RETURN/
# IHBERMAC, SVC macros). These live in libc370; the default used to point at
# crent370, the frozen v1.x libc, which no longer needs to be checked out -- so
# the suite failed with "Undefined operation code ... PDPPRLG" wherever it was
# absent. Override the checkout with LIBC370=/path (same name the Makefile and
# tests/corpus/check.sh already use).
LIBC370=${LIBC370:-../../libc370}
MACLIB="-I $LIBC370/maclib -I $LIBC370/sysmac"
# sample8 (tinitvl, WTO) and sample9 (irxtmpw, XCTL->IHBINNRB) are real rexx370
# modules that exercise the hardest macro paths — they guard against regressing
# the byte-exact REXX corpus when changing the assembler for other projects.
# sample10 is the multiple-distinct-CSECT case (two text-producing sections in
# one assembly): origins stack, each section keeps its own ESD length, and each
# section's TXT card carries its own ESDID.
fail=0
for s in sample1 sample2 sample3 sample4 sample5 sample6 sample7 sample8 sample9 sample10; do
    ./as370 "tests/$s.s" $MACLIB -o "/tmp/$s.obj" >/dev/null 2>&1
    # "Assembled" is RC < 8, the way JCL's COND=(8,LT) let a warned assembly go
    # on to the linkage editor. It matters since #72: sample8/9 expand GETMAIN,
    # and libc370's vendored sysmac/getmain.macro carries a card whose UTF-8
    # transcription of `||` (two bytes per character) pushes it past column 72,
    # so the continuation rule warns at severity 4 on a card that is 80 bytes --
    # and blank in column 72 -- in the EBCDIC member it was copied from.
    [ $? -lt 8 ] || { echo "$s: ASSEMBLE FAILED"; fail=1; continue; }
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

# --- issue #50: ENTRY with a comma-separated symbol list ---------------------
# IFOX00 accepts `ENTRY ALPHA,BETA` and emits one LD per symbol; as370 took the
# whole operand as a single name, so the list tripped the >8-character external
# check and the module did not assemble. There is no IFOX reference deck for the
# list form, so the assertion is an EQUIVALENCE: the list must produce exactly
# the deck the one-ENTRY-per-line spelling produces -- and that spelling is
# pinned to IFOX00 by sample2/3/7 above.
if ! ./as370 tests/entry_list.s -o /tmp/_e50a.obj >/dev/null 2>&1; then
    echo "entry_list: ASSEMBLE FAILED (ENTRY list rejected)"; fail=1
elif ! ./as370 tests/entry_list_1pl.s -o /tmp/_e50b.obj >/dev/null 2>&1; then
    echo "entry_list: ASSEMBLE FAILED (one-per-line control)"; fail=1
elif ! cmp -s /tmp/_e50a.obj /tmp/_e50b.obj; then
    echo "entry_list: MISMATCH (list form != one-ENTRY-per-line form)"; fail=1
else
    echo "entry_list: OK (4-symbol ENTRY == one-ENTRY-per-line deck)"
fi
# The one-per-line control is no longer pinned only through sample2/3/7: once the
# fixture's comment block was trimmed off column 72 (#72 -- IFOX00 read the
# over-long comment as continued and ate the CSECT card behind it), it assembles
# on the guest, and tests/ref/entry_list_1pl.obj is IFOX00's own deck for it.
eref=tests/ref/entry_list_1pl.obj
mysz=$(wc -c < /tmp/_e50b.obj); refsz=$(wc -c < "$eref")
if [ "$mysz" != "$refsz" ]; then
    echo "entry_list: MISMATCH against IFOX00 (deck $mysz vs $refsz bytes)"; fail=1
else
    nbe=$(( (refsz / 80 - 1) * 80 ))
    head -c "$nbe" /tmp/_e50b.obj > /tmp/_ea.$$; head -c "$nbe" "$eref" > /tmp/_eb.$$
    cmp -s /tmp/_ea.$$ /tmp/_eb.$$ \
        && echo "entry_list: OK (one-ENTRY-per-line deck == IFOX00)" \
        || { echo "entry_list: MISMATCH against IFOX00"; fail=1; }
    rm -f /tmp/_ea.$$ /tmp/_eb.$$
fi
rm -f /tmp/_e50a.obj /tmp/_e50b.obj
# EXTRN/WXTRN split the same way but were capped at 8 fields, and the splitter
# drops everything past its maximum without a diagnostic -- so the 9th and later
# symbols of a long EXTRN went missing silently (no ER, no message, RC 0). Ten
# symbols, no V-cons: a V-con would re-register the name by itself and mask it.
printf 'T        CSECT\n         EXTRN E1,E2,E3,E4,E5,E6,E7,E8,E9,E10\n         BR    14\n         END\n' > /tmp/_e50c.s
if ! ./as370 /tmp/_e50c.s -o /tmp/_e50c.obj >/dev/null 2>&1; then
    echo "entry_list: EXTRN 10-symbol ASSEMBLE FAILED"; fail=1
else
    # E9 (C5F9) and E10 (C5F1F0) in EBCDIC -- absent from the deck before the fix
    hex=$(od -An -tx1 /tmp/_e50c.obj | tr -d ' \n')
    if echo "$hex" | grep -q c5f9 && echo "$hex" | grep -q c5f1f0; then
        echo "entry_list: OK (EXTRN 9th/10th symbol reach the ESD -- no silent drop)"
    else
        echo "entry_list: FAIL (EXTRN past the 8th symbol still dropped)"; fail=1
    fi
fi
rm -f /tmp/_e50c.s /tmp/_e50c.obj
# A degenerate empty field (ENTRY A,,B) must not reach sym_get("") -- that name
# is the unnamed private-code section, so it would fabricate a phantom PC ESD
# entry. Same equivalence assertion: the deck must equal the one without the
# stray comma.
printf 'T        CSECT\n         ENTRY A,,B\nA        BR    14\nB        BR    14\n         END\n' > /tmp/_e50d.s
printf 'T        CSECT\n         ENTRY A,B\nA        BR    14\nB        BR    14\n         END\n' > /tmp/_e50e.s
if ! ./as370 /tmp/_e50d.s -o /tmp/_e50d.obj >/dev/null 2>&1 || ! ./as370 /tmp/_e50e.s -o /tmp/_e50e.obj >/dev/null 2>&1; then
    echo "entry_list: empty-field ASSEMBLE FAILED"; fail=1
elif ! cmp -s /tmp/_e50d.obj /tmp/_e50e.obj; then
    echo "entry_list: FAIL (empty ENTRY field changed the deck -- phantom private-code section?)"; fail=1
else
    echo "entry_list: OK (empty ENTRY field skipped, no phantom private-code section)"
fi
rm -f /tmp/_e50d.s /tmp/_e50d.obj /tmp/_e50e.s /tmp/_e50e.obj

# --- issue #51: S/370 instructions missing from the opcode table -------------
# as370's table was built from what the corpus happened to use; against IFOX00's
# own machine-op table (ifox-src/all/genop.asm) 30 S/370 opcodes were absent.
# MP (X'FC') is the one the reporter hit assembling COBOL output. There is no
# IFOX00 reference deck for these, so the assertion is the encoding itself,
# byte-pinned: every operand in the fixture carries an explicit base and
# displacement, and DP -- already in the table and pinned to IFOX00 by the
# corpus -- sits beside MP as the control, so a divergence between FC... and
# FD... would be a table error rather than an encoder error.
# 124 bytes over three TXT cards (56/56/12), so match them card by card.
if ! ./as370 tests/opcodes_370.s -o /tmp/_o51.obj >/dev/null 2>&1; then
    echo "opcodes_370: ASSEMBLE FAILED"; fail=1
else
    hex=$(od -An -tx1 /tmp/_o51.obj | tr -d ' \n')
    c1=fc7310002000fd73100020000812093484051000850610008000100082001000930010009c0010009c0110009d0010009d0110009e001000
    c2=9e0110009f0010009f011000b2001000b2011000b2021000b2031000b2041000b2061000b2071000b2081000b2091000b20d0000b2101000
    c3=b2111000b2121000b2131000
    if echo "$hex" | grep -q "$c1" && echo "$hex" | grep -q "$c2" && echo "$hex" | grep -q "$c3"; then
        echo "opcodes_370: OK (MP == DP shape; RR/SI/S additions byte-pinned)"
    else
        echo "opcodes_370: FAIL (encoding not as pinned)"; fail=1
    fi
fi
rm -f /tmp/_o51.obj
# Deliberate exclusions: TPROT (X'E501', SSE) and IPTE (X'B221', RRE) are in
# IFOX00's table but as370 has neither format. They must stay a LOUD gap -- a
# fabricated encoding would turn RC 8 into silently wrong bytes. This asserts
# the exclusion is deliberate, so a later "completeness" sweep cannot quietly
# add them without an encoder.
for m in TPROT IPTE; do
    printf 'T        CSECT\n         %s 1,2\n         END\n' "$m" > /tmp/_x51.s
    ./as370 /tmp/_x51.s -o /tmp/_x51.obj >/tmp/_x51.out 2>&1
    if [ $? -ne 8 ] || ! grep -q "Undefined operation code" /tmp/_x51.out; then
        echo "opcodes_370: FAIL ($m must stay rejected RC 8 -- as370 has no SSE/RRE format)"; fail=1
    else
        echo "opcodes_370: OK ($m still rejected RC 8 -- documented gap, not silent bytes)"
    fi
done
rm -f /tmp/_x51.s /tmp/_x51.obj /tmp/_x51.out

# --- issue #52: a symbol's owning control section, in the ESD and the RLD -----
# as370 looked up the module's FIRST section instead of the section a symbol is
# defined in. Two symptoms, one root cause:
#   ESD -- the LD entry for an ENTRY in a second or later CSECT named ESDID 1.
#          Cosmetic (IEWL resolves by name), but it is what the reporter saw.
#   RLD -- an ordinary label carries no ESDID of its own, so a relocation whose
#          target lived in a sibling CSECT fell back to the CURRENT section.
#          That is a wrong relocation ESDID, not a naming detail -- and it varied
#          with where the adcon SAT: PLABEL in FIRST got 1, PENT in THIRD got 3.
#   END  -- the entry-point card, same pattern. The loader adds the named
#          section's origin to the address, so this one moves the entry point.
# multi_csect.s carries both, plus three controls that must NOT move: a
# same-section target (R = own section), a target that is itself a CSECT name
# (its own ESDID, always right), and a DSECT target (no RLD entry at all).
# No IFOX00 reference deck exists for this shape -- the corpus has 14 multi-CSECT
# modules and not one of them has an ENTRY or a cross-section adcon to an
# ordinary label -- so the bytes below are pinned from the corrected reading of
# the OS/360 object format, and the corpus proves only that nothing regressed.
# The fixture also carries the #72 case: PDSECT DC A(DSFLD) is IFO158 on IFOX00
# (severity 8), so the RC is 8 and the deck is produced anyway -- exactly what
# the captured reference listing says (tests/listref/ifox-listing-multi-csect.txt:
# "29  IFO158", "NUMBER OF STATEMENTS FLAGGED ... 1", "HIGHEST SEVERITY WAS 8").
./as370 tests/multi_csect.s -o /tmp/_o52.obj >/tmp/_o52.out 2>&1; rc52=$?
if [ $rc52 != 8 ]; then
    echo "multi_csect: expected RC 8 (IFO158 on PDSECT), got $rc52"; fail=1
elif [ "$(grep -c 'IFOX00 IFO158' /tmp/_o52.out)" != 1 ]; then
    echo "multi_csect: expected 1 IFO158 diagnostic, got $(grep -c 'IFOX00 IFO158' /tmp/_o52.out)"; fail=1
else
    hex=$(od -An -tx1 /tmp/_o52.obj | tr -d ' \n')
    # ESD card 1: FIRST (SD, len 10) + SECOND (SD, len 4) + ENT2 (LD, addr 12,
    # owning ESDID 0002 -- was 0001)
    esd=c6c9d9e2e34040400000000040000010e2c5c3d6d5c440400000001040000004c5d5e3f2404040400100001240000002
    # ESD card 2: THIRD. SECOND's contents end at 20, so THIRD's origin is
    # rounded up to 24 (#61) -- this fixture guards that rule too.
    esd2=e3c8c9d9c44040400000001840000004
    # RLD: PSELF R=1 P=1 @8 | PCSNAME R=2 P=1 @0 (+1 = next reuses R/P) |
    #      PLABEL @4 (was R=1) | PENT R=2 P=3 @14 (was R=3). Four items for five
    #      adcons: the DSECT target generates none.
    rld=000100010c000008000200010d0000000c000004000200030c000018
    # END card: entry ENT2 at 000012 in section 0002 (was 0001, an offset into
    # CSECT 2 charged against CSECT 1). Cols 1-16 of the card.
    end=02c5d5c4400000124040404040400002
    if ! echo "$hex" | grep -q "$esd"; then
        echo "multi_csect: FAIL (ESD LD does not name its own section)"; fail=1
    elif ! echo "$hex" | grep -q "$esd2"; then
        echo "multi_csect: FAIL (THIRD's origin is not rounded up to a doubleword)"; fail=1
    elif ! echo "$hex" | grep -q "$rld"; then
        echo "multi_csect: FAIL (RLD relocation ESDIDs not as pinned)"; fail=1
    elif ! echo "$hex" | grep -q "$end"; then
        echo "multi_csect: FAIL (END card entry point does not name its own section)"; fail=1
    else
        echo "multi_csect: OK (ESD/RLD/END name the owning section; THIRD's origin rounded; controls unmoved)"
        echo "multi_csect: OK (the DSECT adcon is IFO158 at RC 8, as on IFOX00 -- and still generates no RLD)"
    fi
fi
rm -f /tmp/_o52.obj /tmp/_o52.out

# --- issue #72: a DSECT symbol in a relocatable address constant = IFO158 -----
# IFOX00 rejects it (severity 8, jermsgcd.asm SEV158) because a dummy section has
# no ESDID to relocate against; as370 emitted the same zero constant and the same
# empty RLD, and said nothing. multi_csect.s above is the DC A(...) oracle. These
# are the cases it does not carry: the same rule reached through a LITERAL, and
# the shapes that must stay clean.
#
# The literal has no IFOX00 oracle of its own -- the rule belongs to the
# constant, not to the statement, so =A(DSFLD) is the same error -- and it is
# charged to the statement that WROTE the literal, not to the LTORG/END that
# assembles the pool (struct lit's defln).
#
# Two statements reference the SAME literal here, deliberately: a literal is one
# pooled constant, assembled once, so it is diagnosed once -- against the first
# reference (line 3), not once per use and not against the END that flushes the
# pool. Pinned because it is a choice, not a law: IFOX00 has no oracle for it.
{ printf 'LITDS    CSECT\n         USING LITDS,15\n'
  printf '         L     2,=A(DSFLD)\n         L     3,=A(DSFLD)\n         BR    14\n'
  printf 'MYDS     DSECT\nDSFLD    DS    F\n         END\n'; } > /tmp/_o72a.s
./as370 /tmp/_o72a.s -o /tmp/_o72a.obj >/tmp/_o72a.out 2>&1; rc72=$?
if [ $rc72 != 8 ]; then
    echo "dsect_adcon: literal =A(DSFLD) not flagged (RC $rc72, expected 8)"; fail=1
elif [ "$(grep -c 'IFOX00 IFO158' /tmp/_o72a.out)" != 1 ]; then
    echo "dsect_adcon: expected 1 IFO158 for the pooled literal, got $(grep -c 'IFOX00 IFO158' /tmp/_o72a.out)"; fail=1
elif ! grep -q 'IFO158.*in line 3' /tmp/_o72a.out; then
    echo "dsect_adcon: literal IFO158 not charged to the first referencing statement (line 3)"; fail=1
else
    echo "dsect_adcon: OK (=A(DSFLD) flagged once, against the statement that wrote the literal)"
fi

# Control 1: two DSECT symbols PAIRED are absolute -- a length, not an address --
# and IFOX00 does not flag that. Control 2: a DC inside a DSECT generates no
# constant at all (sysmac/cvt.macro's own CVTMFRTR DC A(CVTBRET) is this shape,
# and it is why the check tests in_dsect: without that test 23 libc370 modules
# would be flagged for a constant that is never assembled). Control 3: an
# ordinary adcon keeps its RLD entry and its RC 0.
{ printf 'CTLDS    CSECT\n'
  printf 'PDIFF    DC    A(DSFLD-MYDS)\n'
  printf 'PREAL    DC    A(TARGET)\nTARGET   DS    F\n'
  printf 'MYDS     DSECT\nDSFLD    DS    F\n'
  printf 'PINDS    DC    A(DSFLD)\n         END\n'; } > /tmp/_o72b.s
if ./as370 /tmp/_o72b.s -o /tmp/_o72b.obj >/tmp/_o72b.out 2>&1; then
    hex=$(od -An -tx1 /tmp/_o72b.obj | tr -d ' \n')
    # one RLD item only: PREAL at offset 4 (R=P=1); PDIFF is absolute and PINDS
    # sits in the DSECT, which is never assembled
    if echo "$hex" | grep -q "000100010c000004"; then
        echo "dsect_adcon: OK (paired DSECT terms, and a DC inside a DSECT, stay clean at RC 0)"
    else
        echo "dsect_adcon: FAIL (controls assemble clean but the RLD is not the single PREAL item)"; fail=1
    fi
else
    echo "dsect_adcon: FAIL (controls rejected -- over-diagnosis)"; cat /tmp/_o72b.out; fail=1
fi
rm -f /tmp/_o72a.s /tmp/_o72a.obj /tmp/_o72a.out /tmp/_o72b.s /tmp/_o72b.obj /tmp/_o72b.out

# --- issue #72: comment cards take part in the column-72 continuation rule ----
# IFOX00 reads a comment statement with RALLCNT (ifnx1a.asm:606), so a comment
# card reaching column 72 continues -- and the card it consumes is GONE, whether
# it is another comment or a statement. as370 exempted comments outright and
# quietly assembled what the guest had eaten, which made this a byte difference
# and not only a missing diagnostic.
#
# tests/cont72.s is the measurement, tests/listref/ifox-listing-cont72.txt is
# what IFOX00 did with it (JOB02846): RC 4, three statements flagged, five
# IFO026 and one IFO069 -- and CONT72 is EIGHT bytes, because SWALLOW (case A,
# eaten by the comment above it) and CTLC (case C, eaten by the bypass after
# IFO069) never assemble. as370 emitted sixteen.
# The BYTES are IFOX00's; the RETURN CODE deliberately is not. IFOX00 puts a
# discarded statement and a harmless comment-eats-comment at the same severity 4,
# which on MVS passed COND=(8,LT) -- survivable in JCL, not in a host build,
# where a tolerated RC 4 lets silent corruption through CI (mvslovers/nsf370: a
# comment card ate a DCBD, two EQUs and an instruction, and the modules kept
# building). as370 keeps IFO026 at 4 for the harmless case and raises the two
# eaten statements to 8. Section length, TXT and message texts stay the oracle's.
./as370 tests/cont72.s -o /tmp/_c72.obj >/tmp/_c72.out 2>&1; rc72=$?
n26=$(grep -c 'IFO026' /tmp/_c72.out); n69=$(grep -c 'IFO069' /tmp/_c72.out)
nlost=$(grep -c '^ ERROR: This card was consumed' /tmp/_c72.out)
hex=$(od -An -tx1 /tmp/_c72.obj | tr -d ' \n')
if [ $rc72 != 8 ]; then
    echo "cont72: expected RC 8 (two statements discarded), got $rc72"; fail=1
elif [ "$nlost" != 2 ]; then
    echo "cont72: expected 2 discarded statements (SWALLOW, CTLC), got $nlost"; fail=1
elif [ "$n26" != 5 ] || [ "$n69" != 1 ]; then
    echo "cont72: IFOX00's five IFO026 and one IFO069 must all still be cited, got $n26 + $n69"; fail=1
elif ! grep -q '3 Statements Flagged' /tmp/_c72.out; then
    echo "cont72: IFOX00 counts STATEMENTS flagged (3), not messages"; fail=1
elif ! echo "$hex" | grep -q "c3d6d5e3f7f240400000000040000008"; then
    echo "cont72: CONT72 is not 8 bytes -- a swallowed statement was assembled"; fail=1
elif ! echo "$hex" | grep -q "0000000200000003"; then
    echo "cont72: the surviving constants are not CTLA=2 and CTLB=3"; fail=1
else
    echo "cont72: OK (8 bytes and IFOX00's messages; the two eaten statements are RC 8, not 4)"
fi
rm -f /tmp/_c72.obj /tmp/_c72.out
# Control: a comment card that stops before column 72 continues nothing, and a
# continuation card blank in columns 1-15 is not IFO026 -- the rule must not
# fire on the ordinary shape, or every macro operand in the corpus would warn.
{ printf 'CLEAN    CSECT\n* a comment that ends well before column 72\n'
  printf 'KEEP     DC    F%s7%s\n         END\n' "'" "'"; } > /tmp/_c72c.s
if ./as370 /tmp/_c72c.s -o /tmp/_c72c.obj >/tmp/_c72c.out 2>&1 &&
   od -An -tx1 /tmp/_c72c.obj | tr -d ' \n' | grep -q "00000007"; then
    echo "cont72: OK (a comment stopping before column 72 keeps the card after it)"
else
    echo "cont72: FAIL (over-broad -- an ordinary comment ate the next statement)"; cat /tmp/_c72c.out; fail=1
fi
rm -f /tmp/_c72c.s /tmp/_c72c.obj /tmp/_c72c.out

# --- the diagnostic list is bounded; the counts are not ----------------------
# nsf370's nsfvsvc.asm found this the hard way: 130 continuation diagnostics, and
# the two that mattered were the LAST two. At a silent cap of 128 they fell off
# the end, so a module that discarded FOUR statements reported two -- the exact
# failure this diagnostic exists to prevent, reintroduced by its own bookkeeping.
#
# 600 over-long comment cards in one chain, then the statement it eats. The
# printed list stops at MAXCONTD; the count, the overflow line and the return
# code must not.
{ printf 'CAPPED   CSECT\n'
  i=0; while [ $i -lt 600 ]; do printf '%-71sX\n' "* filler card $i reaching column 72"; i=$((i + 1)); done
  printf 'EATEN    DC    F\0477\047\n'
  printf 'KEPT     DC    F\0478\047\n         END\n'; } > /tmp/_cap.s
./as370 /tmp/_cap.s -o /tmp/_cap.obj >/tmp/_cap.out 2>&1; rccap=$?
hexcap=$(od -An -tx1 /tmp/_cap.obj | tr -d ' \n')
if [ $rccap != 8 ]; then
    echo "diag_cap: expected RC 8 -- the discarded statement is past the print limit (got $rccap)"; fail=1
elif ! grep -q 'further continuation diagnostic' /tmp/_cap.out; then
    echo "diag_cap: the overflow is silent again -- no 'further continuation diagnostics' line"; fail=1
elif ! grep -q '1 of them a discarded statement' /tmp/_cap.out; then
    echo "diag_cap: the overflow line does not say a statement was discarded"; fail=1
elif ! echo "$hexcap" | grep -q "00000008"; then
    echo "diag_cap: KEPT did not assemble"; fail=1
elif echo "$hexcap" | grep -q "00000007"; then
    echo "diag_cap: EATEN assembled -- the chain should have consumed it"; fail=1
else
    echo "diag_cap: OK (600 diagnostics: the list is capped, the count, the RC and the loss are not)"
fi
rm -f /tmp/_cap.s /tmp/_cap.obj /tmp/_cap.out

# --- a LIBRARY macro is read to its MEND and not one card further ------------
# SYS1.MACLIB members routinely keep their PL/S source as comment cards AFTER
# the MEND, and some of those cards reach column 72: IEFJESCT's MEND is at
# record 57 with continued cards at 81 and 112, GETMAIN's at 416 with one at 419.
# IFOX00 never reads them -- `IEFJESCT ,` assembles RC 0 on the guest, with
# LIBMAC as well, so they are not merely unlisted -- while the identical card
# INSIDE a definition draws IFO026 and eats the model statement behind it
# (JOB02869). Applying the continuation rule to the whole member gave 21 libc370
# and 12 rexx370 modules a warning on cards the guest does not read.
#
# COPY is the other half of that measurement and is deliberately NOT this case:
# `COPY IEFJESCT` reads the member entire and flags both cards (JOB02866).
mlib=/tmp/_mlib.$$
mkdir -p "$mlib"
{ printf '         MACRO\n&L       TRAILM\n&L       DC    F\0475\047\n         MEND\n'
  printf '%-71sX\n' '* PL/S text kept after MEND, reaching column 72'
  printf '* the card a continued comment would eat\n'; } > "$mlib/trailm.macro"
{ printf '         MACRO\n&L       INSIDM\n'
  printf '%-71sX\n' '* a comment INSIDE the definition, reaching column 72'
  printf '&L       DC    F\0476\047\n         MEND\n'; } > "$mlib/insidm.macro"
# the fixture is only a fixture while that card really is 72 columns
if [ "$(awk 'NR==5{print length($0)}' "$mlib/trailm.macro")" != 72 ]; then
    echo "libmac_mend: BROKEN FIXTURE (the trailing card is not 72 columns)"; fail=1
fi
printf 'LIBM     CSECT\nLBL      TRAILM\n         END\n' > "$mlib/a.s"
printf 'LIBM     CSECT\nLBL      INSIDM\n         END\n' > "$mlib/b.s"
./as370 "$mlib/a.s" -I "$mlib" -o "$mlib/a.obj" >"$mlib/a.out" 2>&1; rcA=$?
./as370 "$mlib/b.s" -I "$mlib" -o "$mlib/b.obj" >"$mlib/b.out" 2>&1; rcB=$?
if [ $rcA != 0 ]; then
    echo "libmac_mend: text after MEND was read (rc $rcA, expected 0)"; cat "$mlib/a.out"; fail=1
elif ! od -An -tx1 "$mlib/a.obj" | tr -d ' \n' | grep -q 00000005; then
    echo "libmac_mend: the macro's own DC F'5' did not survive"; fail=1
elif [ $rcB != 8 ]; then
    echo "libmac_mend: a column-72 comment INSIDE the definition not flagged (rc $rcB, expected 8 -- it eats the model statement)"; fail=1
elif ! grep -q 'IFO026' "$mlib/b.out"; then
    echo "libmac_mend: expected IFO026 for the card inside the definition"; fail=1
elif od -An -tx1 "$mlib/b.obj" | tr -d ' \n' | grep -q 00000006; then
    echo "libmac_mend: the model statement behind that comment should have been eaten"; fail=1
else
    echo "libmac_mend: OK (a library macro stops at MEND; a continued comment inside it still eats the next card)"
fi
rm -rf "$mlib"

# --- issue #68: the END literal pool belongs to the FIRST control section -----
# IFOX00 (xfour.asm, ENDING) resumes the first control section at its highest
# address when END is reached with a non-empty pool, assembles the pool there and
# restores the counter -- so the pool's bytes are punched LAST but carry the
# first section's ESDID and an address inside it, and every section behind the
# first moves up by what the pool took. as370 used to place the pool wherever the
# location counter had reached at END, which lands it in the LAST section: the
# same place only while the module has one section, which is the whole corpus.
#
# The rule itself is validated against IFOX00's own deck on the reporter's
# three-section ksdsnatr (issue #68, now byte-identical apart from the END-card
# IDR). litpool_csect.s is the mechanism test and covers what ksdsnatr does not:
# an LTORG *after* the first section closes (so the pool END flushes is not the
# one open at the boundary, and the LTORG's own pool must stay put), a literal
# first referenced from a LATER section, and an =A literal in the moved pool.
# There is no oracle deck for this shape, so the bytes below are derived from the
# rule; ksdsnatr is what proves the rule.
if ! ./as370 tests/litpool_csect.s -o /tmp/_o68.obj >/dev/null 2>&1; then
    echo "litpool_csect: ASSEMBLE FAILED"; fail=1
else
    hex=$(od -An -tx1 -v /tmp/_o68.obj | tr -d ' \n')   # -v: the card is taken by offset, so no run may collapse
    # ESD: POOLA len 0x20 -- its own 0x12 of content plus the pool at 0x18.
    # POOLB and POOLC are pushed up by it (0x20 and 0x30, not 0x18 and 0x28),
    # and POOLC's length is its own content only: it keeps the LTORG's pool but
    # no longer the END one.
    esd68=d7d6d6d3c14040400000000040000020d7d6d6d3c2404040000000204000000dd7d6d6d3c3404040000000304000000e
    # the pool's TXT card, taken by POSITION: card 4 of 6 (ESD, POOLA's text,
    # POOLC's text, the pool, RLD, END) -- so it is the LAST text card, punched
    # after every other, addressed 0x18 under ESDID 1 (POOLA) and holding =F'2'
    # then =A(ATAB), segment order with first-reference order inside a segment.
    ncards=$(( $(wc -c < /tmp/_o68.obj) / 80 ))
    poolcard=$(echo "$hex" | cut -c481-528)
    # the moved =A's RLD: R=1 P=1 (POOLA, not the section that referenced it)
    rld68=000100010c00001c
    if ! echo "$hex" | grep -q "$esd68"; then
        echo "litpool_csect: FAIL (END pool not charged to the first control section)"; fail=1
    elif [ "$ncards" != 6 ] || [ "$poolcard" != 02e3e7e3400000184040000840400001000000020000000c ]; then
        echo "litpool_csect: FAIL (pool TXT card not last / not addressed in the first section)"; fail=1
    elif ! echo "$hex" | grep -q "$rld68"; then
        echo "litpool_csect: FAIL (moved =A literal does not relocate against the first section)"; fail=1
    elif ! echo "$hex" | grep -q "00000001c1c25820c0165830c01a"; then
        echo "litpool_csect: FAIL (LTORG's own pool moved, or the later references lost their base)"; fail=1
    else
        echo "litpool_csect: OK (END pool in POOLA at 0x18, punched last; LTORG's pool stays in POOLC)"
    fi
fi
rm -f /tmp/_o68.obj

# --- issue #53 (step 1): nothing may reserve zero storage in silence ---------
# The DC/DS type chain ended in a label-only arm with no default: an unhandled
# type defined its label, reserved nothing, did not advance the location counter
# and returned RC 0 -- so every later symbol in the section moved and the ESD
# length agreed with the short figure. CXD was the same shape one layer worse,
# sitting in note_unknown's skip[] and so exempted from diagnosis outright.
#
# Two message classes, and they must stay distinct. Assembler XF has exactly
# fifteen constant types (C X B P Z L D E F H A Y V Q S -- the letters ORGed to
# a non-zero code in IFOX00's DCTBL, ifnx5d.asm:1164). A letter outside that set
# is IFOX00's ERR198 "INVALID TYPE DECLARED ON DC/DS/DXD CONSTANT", severity 8
# (jermsgcd.asm SEV198). P Z E L S Q are VALID types as370 has not implemented;
# calling those invalid would be as misleading as the silence it replaces.
q="'"
dcfail=0
# (a) valid Assembler XF, still unimplemented -> RC 8, "not implemented" wording.
# P and Z left this list when step 2 implemented them, E and L when step 3 did;
# S and Q remain, and stay until the pseudo-register feature lands with them.
for t in "S(T)" "Q(T)"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53.s
    ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
    if [ $? -ne 8 ]; then echo "dc_types: FAIL (DC $t did not give RC 8)"; dcfail=1
    elif ! grep -q "not implemented by as370" /tmp/_d53.out; then
        echo "dc_types: FAIL (DC $t flagged, but not as unimplemented)"; dcfail=1; fi
done
printf 'T        CSECT\nX1       CXD\n         END\n' > /tmp/_d53.s
./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
if [ $? -ne 8 ] || ! grep -q "CXD is valid Assembler XF but not implemented" /tmp/_d53.out; then
    echo "dc_types: FAIL (CXD still silent -- it was exempted in skip[])"; dcfail=1; fi
# (b) letters outside the fifteen -> RC 8, ERR198 wording
for t in "W${q}99${q}" "G${q}1${q}"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53.s
    ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
    if [ $? -ne 8 ]; then echo "dc_types: FAIL (DC $t did not give RC 8)"; dcfail=1
    elif ! grep -q "Invalid type declared on DC/DS/DXD constant" /tmp/_d53.out; then
        echo "dc_types: FAIL (DC $t not reported as ERR198)"; dcfail=1; fi
done
# (b2) no type letter at all -- a bare DS 0, or an empty element in the operand
# list (a trailing comma that is NOT a column-72 continuation). Both are invalid
# to IFOX00 and both used to pass silently; they get their own wording rather
# than "invalid type - ?".
for src in 'A        DS    0' "B        DC    F${q}1${q},"; do
    printf 'T        CSECT\n%s\n         END\n' "$src" > /tmp/_d53.s
    ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
    if [ $? -ne 8 ] || ! grep -q "has no constant type" /tmp/_d53.out; then
        echo "dc_types: FAIL (typeless operand not flagged: $src)"; dcfail=1; fi
done
# a continued DC (column 72) must still assemble -- the folded operand must not
# look like a trailing-comma list to the check above
{ echo 'T        CSECT'
  printf '%-71sX\n' "L1       DC    F${q}1${q},F${q}2${q},"   # continuation marker in column 72
  echo "               F${q}3${q}"
  echo '         END'; } > /tmp/_d53.s
./as370 /tmp/_d53.s -o /tmp/_d53.obj >/dev/null 2>&1 || { echo "dc_types: FAIL (continued DC wrongly rejected)"; dcfail=1; }

# (c) control -- the nine implemented types must NOT be over-rejected
for t in "C${q}A${q}" "X${q}01${q}" "B${q}1${q}" "F${q}1${q}" "H${q}1${q}" "D${q}1${q}" "A(T)" "Y(T)" "V(EXTFOO)" "P${q}1${q}" "Z${q}1${q}" "E${q}1.5${q}" "L${q}1.5${q}"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53.s
    if ! ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/dev/null 2>&1; then
        echo "dc_types: FAIL (implemented type $t wrongly rejected)"; dcfail=1; fi
done
[ $dcfail = 0 ] && echo "dc_types: OK (S Q + CXD loud as unimplemented; W/G as ERR198; implemented types unmoved)"
fail=$((fail + dcfail))
rm -f /tmp/_d53.s /tmp/_d53.obj /tmp/_d53.out

# --- issue #53 (step 2): packed and zoned decimal ----------------------------
# Bytes pinned to IFOX00's PKON/ZKON (ifnx5d.asm:572-663), not to an oracle deck
# -- nothing in the ecosystem uses P or Z, so there is no reference object to
# compare against. See tests/dc_decimal.s for what each case demonstrates.
dzfail=0
if ! ./as370 tests/dc_decimal.s -o /tmp/_d53b.obj >/dev/null 2>&1; then
    echo "dc_decimal: ASSEMBLE FAILED"; dzfail=1
else
    hex=$(od -An -tx1 /tmp/_d53b.obj | tr -d ' \n')
    #     P'123'  P'1234'   P'-123' P'0' PL8'123'          PL2'123456'
    want=123c01234c123d0c000000000000123c456c
    #        Z'456' Z'-456' ZL5'456'    ZL2'12345' P'1.25' 2P'7' P'12,34'
    want=${want}f4f5c6f4f5d6f0f0f4f5c6f4c5125c7c7c012c034c
    if ! echo "$hex" | grep -q "$want"; then echo "dc_decimal: FAIL (bytes not as pinned to PKON/ZKON)"; dzfail=1; fi
    # DS PL8 + DS P reserve 9 more bytes with no text: section length 0x30
    if ! echo "$hex" | grep -q 40000030; then echo "dc_decimal: FAIL (DS PL8 / DS P did not reserve their length)"; dzfail=1; fi
fi
rm -f /tmp/_d53b.obj
# the issue's headline case: PACKED must take 2 bytes and AFTER must land on 8
printf 'TEST     CSECT\nBEFORE   DC    F%s1%s\nPACKED   DC    P%s123%s\nAFTER    DC    F%s2%s\n         DC    A(BEFORE,PACKED,AFTER)\n         END\n' "$q" "$q" "$q" "$q" "$q" "$q" > /tmp/_d53c.s
if ! ./as370 /tmp/_d53c.s -o /tmp/_d53c.obj >/dev/null 2>&1; then
    echo "dc_decimal: FAIL (layout case did not assemble)"; dzfail=1
elif ! od -An -tx1 /tmp/_d53c.obj | tr -d ' \n' | grep -q 00000001123c000000000002000000000000000400000008; then
    echo "dc_decimal: FAIL (BEFORE/PACKED/AFTER not at 0/4/8)"; dzfail=1; fi
rm -f /tmp/_d53c.s /tmp/_d53c.obj
# 65 nominal values in one operand, over three cards. The value-list cap used to
# be 64 and the operand splitter drops the overflow without a diagnostic -- the
# #50 defect, reappearing inside #53's own fix, and worse here: the storage of a
# dropped value is never reserved, so lc under-advances at RC 0 and every later
# symbol shifts. 65 one-byte constants must give a 65-byte section.
if ! ./as370 tests/dc_decimal_list.s -o /tmp/_d53e.obj >/dev/null 2>&1; then
    echo "dc_decimal: FAIL (65-value list did not assemble)"; dzfail=1
elif ! od -An -tx1 /tmp/_d53e.obj | tr -d ' \n' | grep -q 40000041; then
    echo "dc_decimal: FAIL (65-value list: section is not 65 bytes -- a value was dropped)"; dzfail=1
else
    # Once the fixture's comment block was trimmed off column 72 (#72 -- the
    # over-long comment continued and IFOX00 ate the `T CSECT` behind it), this
    # one assembles on the guest too, so it is pinned to a real deck rather than
    # to a section length: tests/ref/dc_decimal_list.obj is IFOX00's own.
    dref=tests/ref/dc_decimal_list.obj
    mysz=$(wc -c < /tmp/_d53e.obj); refsz=$(wc -c < "$dref")
    if [ "$mysz" != "$refsz" ]; then
        echo "dc_decimal: FAIL (65-value deck $mysz vs IFOX00 $refsz bytes)"; dzfail=1
    else
        nbe=$(( (refsz / 80 - 1) * 80 ))
        head -c "$nbe" /tmp/_d53e.obj > /tmp/_da.$$; head -c "$nbe" "$dref" > /tmp/_db.$$
        cmp -s /tmp/_da.$$ /tmp/_db.$$ || { echo "dc_decimal: FAIL (65-value list != IFOX00 deck)"; dzfail=1; }
        rm -f /tmp/_da.$$ /tmp/_db.$$
    fi
fi
rm -f /tmp/_d53e.obj
# nominal values the constant's own rules reject -- each RC 8, none silent.
# The blanks matter: PKON tests each character against J9 (X'09') and JBLANK is
# X'2F' (jcommon.asm), so a blank falls through to XBERR1 and IFOX raises ERR236.
# Skipping a leading one, or stopping at an embedded one, would silently accept
# P' 123' and quietly truncate P'1 2' to 1C.
for t in "P${q}1.2.3${q}" "P${q}12X4${q}" "P${q}123456789012345678901234567890123${q}" "Z${q}12345678901234567${q}" "PL20${q}1${q}" "P${q}${q}" "P" "P${q} 123${q}" "P${q}1 2${q}" "Z${q}4 5${q}"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53d.s
    ./as370 /tmp/_d53d.s -o /tmp/_d53d.obj >/dev/null 2>&1
    [ $? -eq 8 ] || { echo "dc_decimal: FAIL (DC $t accepted, expected RC 8)"; dzfail=1; }
done
rm -f /tmp/_d53d.s /tmp/_d53d.obj
[ $dzfail = 0 ] && echo "dc_decimal: OK (P/Z bytes pinned to PKON/ZKON; layout fixed; 65-value list intact; 10 value errors rejected)"
fail=$((fail + dzfail))

# --- issue #53 (step 3): floating point, against IFOX00's own deck ------------
# tests/ref/fltoracl.obj is IFOX00's deck for tests/fltoracl.s, assembled on an
# MVS 3.8j guest and fetched back byte-for-byte. Unlike hello/arith/litmove this
# oracle is ours rather than the reporter's -- it had to be, and that is the
# point: the mvslovers corpus contains no floating-point constant and no D/E/L
# literal at all, and the reporter's COBOL-74 compiler cannot emit one (see #53),
# so nothing in reach could have validated these encodings.
#
# The deck rather than the listing, because IFOX prints at most eight object
# bytes per statement line: the LOW halves of the 16-byte L constants and the
# second element of D'1.5,2.5' exist only here.
#
# What used to happen, all at RC 0: D sat in the integer arm, so D'1.5' assembled
# as 0000000000000001 where IFOX says 4118000000000000 and D'-1.5' as all ones;
# E and L reserved nothing; on the literal path the converter was reached only
# when the text contained a '.', 'e' or 'E', so =D'2' and =E'1' took the integer
# route; and =L had no arm at all, so it reserved four bytes instead of sixteen
# and sorted into the pool's fullword segment instead of its doubleword one.
#
# No macros, so it runs from a plain checkout -- no SYS1MAC, no skip.
if ! ./as370 tests/fltoracl.s -o /tmp/_f53.obj >/dev/null 2>&1; then
    echo "fltoracl: ASSEMBLE FAILED"; fail=1
else
    fref=tests/ref/fltoracl.obj
    fmy=$(wc -c < /tmp/_f53.obj); frf=$(wc -c < "$fref")
    if [ "$fmy" != "$frf" ]; then echo "fltoracl: MISMATCH (deck $fmy vs $frf bytes)"; fail=1
    else
        fn=$(( (frf / 80 - 1) * 80 ))
        head -c "$fn" /tmp/_f53.obj > /tmp/_fa.$$; head -c "$fn" "$fref" > /tmp/_fb.$$
        if cmp -s /tmp/_fa.$$ /tmp/_fb.$$; then
            echo "fltoracl: OK (== IFOX00 -- D/E/L values, extended low halves, rounding, and the =D/=E/=L pool)"
        else
            echo "fltoracl: MISMATCH"; fail=1
        fi
        rm -f /tmp/_fa.$$ /tmp/_fb.$$
    fi
fi
rm -f /tmp/_f53.obj

# --- issue #52: a REAL IFOX00 deck as the oracle for the multi-CSECT shape ----
# tests/ref/hello.obj is IFOX00's own object deck for tests/hello.s, contributed
# by the #52 reporter along with the source. It is generated output from a
# COBOL-74 compiler, not a constructed case: three CSECTs -- the program, COBWS
# for WORKING-STORAGE, COBRT for the runtime -- with all four ENTRY points
# defined in the THIRD control section and V-type adcons between them.
#
# That matters because it is the one thing the corpus cannot give us. libc370
# has 14 multi-CSECT modules and not one of them has an ENTRY or a cross-section
# adcon to an ordinary label, so #52's ESD/RLD/END fix was pinned to a reading of
# the object format rather than to an oracle. This deck IS the oracle: 31 cards
# byte-identical, the END card differing only in the translator identification
# (15741SC103 against ASM370) and its Julian date, which is why -- as everywhere
# else in this file -- the comparison stops before the END card.
#
# It needs SYS1.MACLIB's SPIE and TIME, which libc370's sysmac mirror does not
# carry (mvslovers/libc370#155). Point SYS1MAC=<dir> at a SYS1.MACLIB extract to
# run it; without them the fixture SKIPS rather than failing, so a plain checkout
# stays green and the gap stays visible.
SYS1MAC=${SYS1MAC:-$LIBC370/sysmac}
if [ ! -f "$SYS1MAC/spie.macro" ] || [ ! -f "$SYS1MAC/time.macro" ]; then
    echo "hello: SKIPPED (needs SYS1.MACLIB SPIE + TIME -- mvslovers/libc370#155; set SYS1MAC=<dir>)"
elif ! ./as370 tests/hello.s $MACLIB -I "$SYS1MAC" -o /tmp/_hel.obj >/dev/null 2>&1; then
    echo "hello: ASSEMBLE FAILED"; fail=1
else
    href=tests/ref/hello.obj
    hmy=$(wc -c < /tmp/_hel.obj); hrf=$(wc -c < "$href")
    if [ "$hmy" != "$hrf" ]; then
        echo "hello: MISMATCH (deck $hmy vs $hrf bytes)"; fail=1
    else
        hn=$(( (hrf / 80 - 1) * 80 ))
        head -c "$hn" /tmp/_hel.obj > /tmp/_ha.$$; head -c "$hn" "$href" > /tmp/_hb.$$
        if cmp -s /tmp/_ha.$$ /tmp/_hb.$$; then
            echo "hello: OK (== IFOX00 -- 3 CSECTs, 4 ENTRYs in the third, V-adcons between)"
        else
            echo "hello: MISMATCH"; fail=1
        fi
        rm -f /tmp/_ha.$$ /tmp/_hb.$$
    fi
fi
rm -f /tmp/_hel.obj

# --- issue #61: CSECT origins on real generated code -------------------------
# tests/litmove.s is contributed generated output; the three ESD cards below are
# IFOX00's own, byte for byte, from the deck the reporter assembled on an MVS
# 3.8j guest. COBWS is 13 bytes at 0x398 and so ends at 0x3A5, off a doubleword:
# IFOX00 rounds COBRT's origin up to 0x3A8 and leaves COBWS's length at 13. That
# pair -- rounded origin, unrounded length -- is the whole of #61, and it cannot
# be got from a single pinned number.
#
# The ESD cards only, deliberately. Three text bytes still differ and neither is
# an as370 defect: the source's [ and ] reached the guest as X'AD'/X'BD' while
# as370 maps them per CP037 to X'BA'/X'BB', the table the mvslovers upload path
# uses -- tracked as #74. Its companion arith became a full-deck fixture when
# #64 (SRP) landed, and ksdsnatr is the third.
if [ ! -f "$SYS1MAC/spie.macro" ] || [ ! -f "$SYS1MAC/time.macro" ]; then
    echo "litmove: SKIPPED (needs SYS1.MACLIB SPIE + TIME -- mvslovers/libc370#155; set SYS1MAC=<dir>)"
elif ! ./as370 tests/litmove.s $MACLIB -I "$SYS1MAC" -o /tmp/_lm.obj >/dev/null 2>&1; then
    echo "litmove: ASSEMBLE FAILED"; fail=1
else
    lmhex=$(od -An -tx1 /tmp/_lm.obj | tr -d ' \n')
    lm1=02c5e2c4404040404040003040400001d3c9e3d4d6e5c5400000000040000398c3d6c2c4c9e2d7400200000040404040c3d6c2e3c5d9d4400200000040404040
    lm2=02c5e2c4404040404040003040400004c3d6c2e6e2404040000003984000000dc3d6c2d9e3404040000003a840000474c3d6c2c4c9e2d740010003a840000005
    lm3=02c5e2c4404040404040003040404040c3d6c2e3c5d9d4400100042040000005c3d6c2e6d9d340400100057840000005c3d6c2c4c1e3c5400100045640000005
    lmbad=0
    for w in "$lm1" "$lm2" "$lm3"; do echo "$lmhex" | grep -q "$w" || lmbad=1; done
    if [ $lmbad = 0 ]; then
        echo "litmove: OK (ESD == IFOX00 -- COBRT origin rounded to 0x3A8, COBWS length still 13)"
    else
        echo "litmove: FAIL (ESD does not match IFOX00's)"; fail=1
    fi
fi
rm -f /tmp/_lm.obj

# --- issue #64: SRP's length nibble and its rounding digit --------------------
# SRP is the third shape in the X'Fx' SS group: one length in the HIGH nibble and
# an IMMEDIATE -- the rounding digit -- in the low one. as370 treated it as a
# one-length instruction, writing the length across the whole byte and never
# parsing the third operand, so the length reached the machine as the rounding
# digit and every SRP that asked for rounding got none. Both at RC 0.
srpfail=0
printf 'T        CSECT\n         USING T,12\n         SRP   P1(8),1,0\n         SRP   P1(8),64-2,5\nP1       DS    PL8\n         END\n' > /tmp/_s64.s
if ! ./as370 /tmp/_s64.s -o /tmp/_s64.obj >/dev/null 2>&1; then
    echo "srp: ASSEMBLE FAILED"; srpfail=1
elif ! od -An -tx1 /tmp/_s64.obj | tr -d ' \n' | grep -q f070c00c0001f075c00c003e; then
    echo "srp: FAIL (encoding not L1 in the high nibble, I3 in the low)"; srpfail=1
fi
# the three operands SRP rejects. A missing one is IFOX00's ERR177 at severity
# 12, not the 8 the others carry -- assert the RC so the distinction cannot be
# quietly flattened back to a shared floor.
printf 'T        CSECT\n         USING T,12\n         SRP   P1(8),1\nP1       DS    PL8\n         END\n' > /tmp/_s64.s
./as370 /tmp/_s64.s -o /tmp/_s64.obj >/tmp/_s64.out 2>&1
[ $? -eq 12 ] && grep -q "needs a third operand" /tmp/_s64.out || { echo "srp: FAIL (missing I3 not RC 12 / ERR177)"; srpfail=1; }
for t in "SRP   P1(8),1,10" "SRP   P1(8),1,P1"; do
    printf 'T        CSECT\n         USING T,12\n         %s\nP1       DS    PL8\n         END\n' "$t" > /tmp/_s64.s
    ./as370 /tmp/_s64.s -o /tmp/_s64.obj >/dev/null 2>&1
    [ $? -eq 8 ] || { echo "srp: FAIL ($t accepted, expected RC 8)"; srpfail=1; }
done
[ $srpfail = 0 ] && echo "srp: OK (F0 70 / F0 75 pinned; missing I3 = RC 12, out-of-range and relocatable = RC 8)"
fail=$((fail + srpfail))
rm -f /tmp/_s64.s /tmp/_s64.obj /tmp/_s64.out
# tests/ref/arith.obj is IFOX00's own deck for tests/arith.s -- the same
# contributor, the same extraction path as hello. Five SRP occurrences and the
# #61 origin rounding in one module, so it is the end-to-end regression for both.
if [ ! -f "$SYS1MAC/spie.macro" ] || [ ! -f "$SYS1MAC/time.macro" ]; then
    echo "arith: SKIPPED (needs SYS1.MACLIB SPIE + TIME -- mvslovers/libc370#155; set SYS1MAC=<dir>)"
elif ! ./as370 tests/arith.s $MACLIB -I "$SYS1MAC" -o /tmp/_ar.obj >/dev/null 2>&1; then
    echo "arith: ASSEMBLE FAILED"; fail=1
else
    aref=tests/ref/arith.obj
    amy=$(wc -c < /tmp/_ar.obj); arf=$(wc -c < "$aref")
    if [ "$amy" != "$arf" ]; then echo "arith: MISMATCH (deck $amy vs $arf bytes)"; fail=1
    else
        an=$(( (arf / 80 - 1) * 80 ))
        head -c "$an" /tmp/_ar.obj > /tmp/_ara.$$; head -c "$an" "$aref" > /tmp/_arb.$$
        if cmp -s /tmp/_ara.$$ /tmp/_arb.$$; then
            echo "arith: OK (== IFOX00 -- 5 SRP, and COBRT's origin rounded to 0x580)"
        else
            echo "arith: MISMATCH"; fail=1
        fi
        rm -f /tmp/_ara.$$ /tmp/_arb.$$
    fi
fi
rm -f /tmp/_ar.obj

# --- #68 / #61 / #63: the third full deck, and the one that found all three ---
# tests/ref/ksdsnatr.obj is IFOX00's own deck for tests/ksdsnatr.s, contributed
# by the #52/#61 reporter with permission to carry it here (#68). It is the most
# informative of the three: arith carries SRP and hello the multi-CSECT ENTRY
# shape, but this module has three control sections, VSAM macro expansions and a
# literal pool at once, so one comparison regresses three rules together --
# #61's origin rounding and section lengths, #63's DCB expansion, and #68's END
# pool going to the FIRST control section.
#
# 1336 differing bytes when it arrived; byte-identical now. Nothing constructed
# would have found those three, and nothing in the corpus contains them: it has
# no genuinely multi-section module at all, and no literal referenced before a
# later section.
#
# Same SPIE + TIME dependency as hello and arith, so it skips the same way.
if [ ! -f "$SYS1MAC/spie.macro" ] || [ ! -f "$SYS1MAC/time.macro" ]; then
    echo "ksdsnatr: SKIPPED (needs SYS1.MACLIB SPIE + TIME -- mvslovers/libc370#155; set SYS1MAC=<dir>)"
elif ! ./as370 tests/ksdsnatr.s $MACLIB -I "$SYS1MAC" -o /tmp/_ks.obj >/dev/null 2>&1; then
    echo "ksdsnatr: ASSEMBLE FAILED"; fail=1
else
    kref=tests/ref/ksdsnatr.obj
    kmy=$(wc -c < /tmp/_ks.obj); krf=$(wc -c < "$kref")
    if [ "$kmy" != "$krf" ]; then echo "ksdsnatr: MISMATCH (deck $kmy vs $krf bytes)"; fail=1
    else
        kn=$(( (krf / 80 - 1) * 80 ))
        head -c "$kn" /tmp/_ks.obj > /tmp/_ka.$$; head -c "$kn" "$kref" > /tmp/_kb.$$
        if cmp -s /tmp/_ka.$$ /tmp/_kb.$$; then
            echo "ksdsnatr: OK (== IFOX00 -- 3 CSECTs, VSAM expansions, and the END pool in the first section)"
        else
            echo "ksdsnatr: MISMATCH"; fail=1
        fi
        rm -f /tmp/_ka.$$ /tmp/_kb.$$
    fi
fi
rm -f /tmp/_ks.obj

# --- issue #63: two silent truncations that made a DCB twelve bytes short ------
# Both had the same shape -- a bound exceeded without a word said -- and both
# showed up only as wrong object bytes at RC 0.
#
#  (a) parse() writes up to 1023 characters of operand, and two callers gave it
#      a 128-byte buffer. Continuations are folded before a macro library is
#      read, so a macro body carrying a multi-card statement overflowed the
#      stack; SYS1.MACLIB's DCB has seven such statements, the longest 1376
#      characters. Confirmed with AddressSanitizer, which named parse() called
#      from capture_macro().
#  (b) the list of names known to be global capped at 64 and dropped the rest.
#      In a module that also expands the VSAM macros, 138 names were dropped --
#      among them IHB01's &COMSW, so `&COMSW SETB 1` went to IHB01's own local
#      table and DCB read back an unset, and therefore false, switch. The macro
#      then took the wrong branch and skipped the common-interface block.
#
# tests/vsam_dcb.s is the end-to-end regression, and it needs the VSAM macros in
# front of the DCB -- an isolated DCB expands correctly even with the bug, which
# is why this needed a real module to surface. The QSAM DCB must carry BUFNO,
# BUFCB, BUFL, DSORG and IOBAD ahead of its DDNAME, X'4000' being DSORG=PS.
dcbfail=0
if ! ./as370 tests/vsam_dcb.s $MACLIB -o /tmp/_d63.obj >/dev/null 2>&1; then
    echo "dcb: ASSEMBLE FAILED"; dcbfail=1
elif ! od -An -tx1 /tmp/_d63.obj | tr -d ' \n' | grep -q 0000000100004000000000010000000100000000c3c1d9c4c9d54040; then
    echo "dcb: FAIL (common-interface block missing -- DCB is 12 bytes short)"; dcbfail=1
fi
rm -f /tmp/_d63.obj
# and the global-name cap on its own: 80 declared globals, the last one SET by an
# inner macro and read by the outer. Past 64 the name was no longer known to be
# global, so the assignment went to the inner macro's local table and vanished.
{ echo '         MACRO'; echo '         SETLAST'; echo '         GBLB  &GLAST'
  echo '&GLAST   SETB  1'; echo '         MEND'
  echo '         MACRO'; echo '         BIGGBL'
  i=1; while [ $i -le 80 ]; do
      l='         GBLB  '; j=0
      while [ $j -lt 8 ] && [ $i -le 80 ]; do
          n=$(printf 'G%03d' $i); [ $j -gt 0 ] && l="$l,"; l="$l&$n"; i=$((i+1)); j=$((j+1))
      done; echo "$l"
  done
  echo '         GBLB  &GLAST'; echo '         SETLAST'
  echo '         AIF   (NOT &GLAST).NO'; echo "YES      DC    C'YES'"; echo '         AGO   .E'
  echo '.NO      ANOP'; echo "NO       DC    C'NO'"; echo '.E       ANOP'; echo '         MEND'
  echo 'T        CSECT'; echo '         BIGGBL'; echo '         END'; } > /tmp/_g63.s
if ! ./as370 /tmp/_g63.s -o /tmp/_g63.obj >/dev/null 2>&1; then
    echo "dcb: global-cap ASSEMBLE FAILED"; dcbfail=1
elif ! od -An -tx1 /tmp/_g63.obj | tr -d ' \n' | grep -q e8c5e2; then
    echo "dcb: FAIL (a global past the 64th is silently dropped)"; dcbfail=1
fi
rm -f /tmp/_g63.s /tmp/_g63.obj
[ $dcbfail = 0 ] && echo "dcb: OK (QSAM DCB carries its common-interface block; the 65th global survives)"
fail=$((fail + dcbfail))

[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
