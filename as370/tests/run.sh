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
if ! ./as370 tests/multi_csect.s -o /tmp/_o52.obj >/dev/null 2>&1; then
    echo "multi_csect: ASSEMBLE FAILED"; fail=1
else
    hex=$(od -An -tx1 /tmp/_o52.obj | tr -d ' \n')
    # ESD card 1: FIRST (SD, len 10) + SECOND (SD, len 4) + ENT2 (LD, addr 12,
    # owning ESDID 0002 -- was 0001)
    esd=c6c9d9e2e34040400000000040000010e2c5c3d6d5c440400000001040000004c5d5e3f2404040400100001240000002
    # RLD: PSELF R=1 P=1 @8 | PCSNAME R=2 P=1 @0 (+1 = next reuses R/P) |
    #      PLABEL @4 (was R=1) | PENT R=2 P=3 @14 (was R=3). Four items for five
    #      adcons: the DSECT target generates none.
    rld=000100010c000008000200010d0000000c000004000200030c000014
    # END card: entry ENT2 at 000012 in section 0002 (was 0001, an offset into
    # CSECT 2 charged against CSECT 1). Cols 1-16 of the card.
    end=02c5d5c4400000124040404040400002
    if ! echo "$hex" | grep -q "$esd"; then
        echo "multi_csect: FAIL (ESD LD does not name its own section)"; fail=1
    elif ! echo "$hex" | grep -q "$rld"; then
        echo "multi_csect: FAIL (RLD relocation ESDIDs not as pinned)"; fail=1
    elif ! echo "$hex" | grep -q "$end"; then
        echo "multi_csect: FAIL (END card entry point does not name its own section)"; fail=1
    else
        echo "multi_csect: OK (ESD/RLD/END name the owning section; same-section, CSECT-name and DSECT controls unmoved)"
    fi
fi
rm -f /tmp/_o52.obj

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
# P and Z left this list when step 2 implemented them; E L S Q remain.
for t in "E${q}1.5${q}" "L${q}1.5${q}" "S(T)" "Q(T)"; do
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
for t in "C${q}A${q}" "X${q}01${q}" "B${q}1${q}" "F${q}1${q}" "H${q}1${q}" "D${q}1${q}" "A(T)" "Y(T)" "V(EXTFOO)" "P${q}1${q}" "Z${q}1${q}"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53.s
    if ! ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/dev/null 2>&1; then
        echo "dc_types: FAIL (implemented type $t wrongly rejected)"; dcfail=1; fi
done
[ $dcfail = 0 ] && echo "dc_types: OK (E L S Q + CXD loud as unimplemented; W/G as ERR198; implemented types unmoved)"
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
    echo "dc_decimal: FAIL (65-value list: section is not 65 bytes -- a value was dropped)"; dzfail=1; fi
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

[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
