#!/bin/sh
# Assemble each sample and verify the object deck (all cards before the END
# card, which legitimately differs only in the IDR) is byte-identical to the
# IFOX00 reference in tests/ref/.
#
# BEFORE ADDING A TEST HERE, CHECK THAT IT FAILS WITHOUT THE FIX.
# A fixture that passes on both binaries is not a weak test, it is a NON-test,
# and it is indistinguishable from a passing one ever after. Two were caught
# only by running them against the old binary on purpose:
#   - rldlen.s (#186) first used an A-con in the DSECT. The clobbering call site
#     is the V-con path, so it passed both ways and proved nothing.
#   - attrapos.s (#149) needed a THIRD case: the obvious fix passes the macro
#     parameter and literal-identity cases and fails only on the closing quote
#     of a string ending in an attribute letter -- the case that cost 96 decks.
# So: build the fixture, run the PRE-fix binary against it, and record in the
# comment what that binary scores. If you cannot make it score differently, the
# fixture is not testing the change.
#
# TWO SHARPER FORMS OF THE SAME RULE, both learned the expensive way:
#
#   Make it fail for exactly ONE of the hypotheses you are choosing between.
#   cmprule.s (#153) began as the macro loop alone: as370 one entry, IFOX eleven.
#   That proves as370 wrong and leaves BOTH candidate rules standing, because on
#   decimals "arithmetic" and "length-first" agree. Only the letter cases
#   ('B' LE 'AB') separate them. A fixture that fails correctly and cannot tell
#   the candidates apart is still a coin toss with a passing test either way.
#
#   Carry a CONTROL that can fail and constrains the fix in a direction the
#   target case does not. absusing.s (#190) keeps a relocatable `USING *,15' in
#   force over the whole CSECT, measured never to be used for the absolute
#   operand -- before and after the absolute USING is dropped. The target case
#   says what must resolve; the control says what must NOT, and only the control
#   would catch a fix that resolves absolute operands through any USING at all.
#
# And do not trust this suite alone for an as370 change. 743 corpus modules and
# every reference deck here stayed green through a version of #149 that cost 96
# identities on the 5,528-module tree, because not one of them contains a string
# ending in an attribute letter. The mvs38src tree-wide gate is the instrument,
# and its LOST line is the one that matters.
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
# ssb1 is the #203 oracle: the first subscript of an SS operand 1 is the LENGTH,
# so the base is never sub[0] there -- nor for operand 2 of a two-length SS. But
# sub[0] is OVERLOADED and `ns' is what distinguishes: with no list written,
# resolve() leaves the USING-chosen base in sub[0], so case 3 is the control that
# fails on a fix which suppresses the fallback outright.
#   main 4907207   D501208E D501508E D501C000 F922C004 F922308E
#   IFOX00, this   D501008E D501508E D501C000 F922C004 F922008E
# ssomit is the #201 oracle: an SS operand's IMPLIED length, by two routes. An
# omitted length is not a length of zero -- `CLC DA-D(,5)' writes the subscript
# list for its base and leaves the length field empty -- and an ABSOLUTE prefix
# still has a length attribute, which is the form with no parentheses at all.
# The last case is the control: a purely numeric prefix has no length attribute
# and must stay 1, so a fix that hands out L' indiscriminately fails here.
#   main 021db88   D503 D500 D500 D503 D500
#   IFOX00, this   D503 D503 D503 D503 D500
# entsd is the other #199 oracle: an ENTRY naming a CONTROL SECTION gets no LD --
# the SD already is that entry point. LAB is the control: an ENTRY on an ordinary
# label keeps its LD, so a fix that drops LD entries generally fails there.
#   main d398f1e   T LD, LAB LD, T SD
#   IFOX00, this   LAB LD, T SD
# esdself is the #199 oracle: an ESDID belongs to the ESD ENTRY, not the symbol.
# One name can hold two entries -- a CSECT that V-cons its own name has an SD and
# an ER -- and IFOX00 numbers them separately. The R field is the control: it must
# still take the ER (2) and not the SD (1), because a V-con names an external even
# when that name is also defined here. P must take the SD.
#   main 789eb19   SD=2 ER=3 EXTA=4   P=0002
#   IFOX00, this   SD=1 ER=2 EXTA=3   P=0001, R=0002
# equlen is the #194 oracle: L' of an EQU is the length attribute of the LEFTMOST
# TERM, and only when that term is a symbol. `1+A' is what fixes the rule -- it
# is the leftmost TERM, not the first symbol in the expression, so an expression
# opening with a number gets 1 though a symbol follows. Without that case
# "leftmost term" and "first symbol" cannot be told apart. The trailing CLC is
# the consequence and it must name an EQU symbol, not a DS label: SS instructions
# read L' as their IMPLIED LENGTH, and a DS label has the right L' either way.
#   main 4b8785f   04 02 01 01 01 01 04 01 01 01   CLC D500
#   IFOX00, this   04 02 04 04 01 01 04 02 02 01   CLC D503
# --- issue #173: a subscripted SET array is one table row ---------------------
# 20,000 distinct subscripts, deliberately far above any bound: the case tells a
# STRUCTURAL change from a raised one. At 600 a MAXLSET of 1,024 would pass it.
# No deck to compare -- the assertion is that it assembles at all.
#   main e5e4430   local SET-symbol table full (512)
if ./as370 tests/setarray.s -o /dev/null >/dev/null 2>&1; then
    echo "setarray: OK (20,000 subscripts, one row)"
else echo "setarray: FAIL (SET table filled)"; fail=1; fi

# --- issue #39: MNOTE is the macro's own diagnostic --------------------------
# Its own module because as370 now returns 12, so the generic deck loop (which
# requires rc < 8) would report ASSEMBLE FAILED on a correct binary. The deck is
# a single `DC C'X'' and proves nothing; the claim is entirely about what was
# SAID and what the return code became.
#
# The two lower forms are the controls: `MNOTE *,'..'' and `MNOTE '..'' are
# printed and cost nothing -- neither the flagged count nor the RC may move for
# them. A fix that counts every MNOTE gets 6 flagged instead of 4 and fails here.
#   main 80c3ba2   rc 0, nothing printed at all
#   IFOX00, this   rc 12, 4 statements flagged
./as370 tests/mnote.s -o /dev/null > /tmp/_mn.$$ 2>&1; mnrc=$?
mnok=1
[ "$mnrc" = 12 ] || mnok=0
grep -q "4 Statements Flagged" /tmp/_mn.$$ || mnok=0
grep -q "ERROR: MNOTE .* - EIGHT FROM A MACRO" /tmp/_mn.$$ || mnok=0
grep -q "WARNING: MNOTE .* - FOUR FROM A MACRO" /tmp/_mn.$$ || mnok=0
grep -q "NOTE: MNOTE .* - COMMENT FORM" /tmp/_mn.$$ || mnok=0
grep -q "NOTE: MNOTE .* - NO SEVERITY GIVEN" /tmp/_mn.$$ || mnok=0
grep -q "ERROR: MNOTE .* - TWELVE WITH A 'QUOTE' INSIDE" /tmp/_mn.$$ || mnok=0
grep -q "WARNING: MNOTE .* - FOUR IN OPEN CODE" /tmp/_mn.$$ || mnok=0
if [ $mnok = 1 ]; then
    echo "mnote: OK (rc 12, 4 flagged; the * and bare forms cost nothing)"
else echo "mnote: MISMATCH (rc $mnrc, see /tmp/_mn.$$)"; fail=1; fi
rm -f /tmp/_mn.$$

# --- issue #190: an undefined symbol is not an absolute domain ---------------
# Its own module because IFOX00 flags the undefined symbol (rc 12) and writes no
# deck, so the check is on the listing. An undefined symbol evaluates to 0 and
# non-relocatable exactly like an absolute one; taking that for an absolute USING
# gives every absolute operand in the module a base, and cost 52 identities.
#   over-broad   58605010      IFOX00 and this   58600010
./as370 tests/absundef.s -a -o /dev/null > /tmp/_au.$$ 2>&1
if grep -qE "^0000[0-9A-F]{2} 5860 0010" /tmp/_au.$$; then
    echo "absundef: OK (== IFOX00 -- undefined symbol gets no base)"
else echo "absundef: MISMATCH (see /tmp/_au.$$)"; fail=1; fi
rm -f /tmp/_au.$$

# absusing is the #190 oracle: an ABSOLUTE operand is addressed through an
# ABSOLUTE using, and only through one. The `USING *,15' over the whole CSECT is
# the control that matters -- IFOX00 never uses R15 for the absolute operand,
# before or after the absolute USING is dropped, so the two kinds do not mix.
#   main 6e578f4   4110 0100   5830 0100   4140 0100
#   IFOX00, this   4110 2100   5830 2100   4140 0100
# cmprule is the #153 oracle: a character comparison orders by LENGTH first, so a
# shorter string is less than a longer one whatever the characters are. Six cases
# separate that from strcmp AND from "arithmetic when both are numbers" -- the
# letter cases D and F do the separating, because on numbers alone arithmetic and
# length-first agree. G and H are equal-length controls where content decides and
# nothing should move. Scores:
#   main 3b5b3ff   AN BN CJ DN EJ FJ GJ HN
#   IFOX00, this   AJ BJ CN DJ EJ FN GJ HN
# contattr is the #184 oracle: join_cont() decides where the FIRST card's operand
# ends, so an attribute apostrophe there folds the remark into the joined
# statement. Three cases and the third is the one that earns its place -- it
# fails only on a fix that uses attr_apos() WITHOUT the `q ||' guard, which is
# the omission that cost 96 decks in #182. Scores against the two wrong binaries,
# recorded so the next reader does not have to rebuild them:
#   main 3eb1a48        DC C''    DC C'DD'  DC C'EE'
#   attr_apos, no guard DC C'CC'  DC C'DD'  DC C''
#   IFOX00 and this     DC C'CC'  DC C'DD'  DC C'EE'
# rldlen is the #186 oracle: the length in an RLD flag byte belongs to ITS entry.
# add_reloc() bails on in_dsect, but the call site wrote the width afterwards
# into rels[nrel-1] -- the PREVIOUS, real entry. An address constant in a DSECT
# is ordinary (IEAVELCR: 24 real calls, 138 from dummy sections), so the last
# real entry kept the width of the last DSECT constant. One bit of one flag byte
# in an otherwise byte-identical deck, on 173 modules.
# attrapos is the #149 oracle and carries three cases, because the obvious fix
# fails the third: an attribute apostrophe (L'A) is not a quote, so parse() must
# not toggle on it -- but INSIDE a string an apostrophe can only close it, and
# attr_apos() is a purely lexical test that does not know that. Without the
# `q ||' guard the closing quote of 'S' reads as an attribute (S is an attribute
# letter), the string never closes, and 96 decks lost their identity.
# contparen is #154's third-cause oracle, and it carries BOTH halves of the rule
# because each half alone breaks the other: a macro call ends its operand at the
# first blank outside quotes even inside an open paren (so the remark is dropped),
# while AIF/SETB operands are expressions whose operators are blank-separated and
# must be joined across the continuation. Honouring parens everywhere swallowed
# the remark; honouring them nowhere broke AIF and took the #63 DCB with it.
# equsect is the #154 oracle: a relocatable EQU belongs to the section of its
# VALUE, not to the section its card sits in. The fixture equates two symbols to
# the SAME label -- one card in the CSECT, one under a DSECT -- so IFOX00's deck
# pins them to the same instruction (both 47F0 C00C). as370 used to take the
# DSECT's base register for the second and say nothing.
# ccwstar is the #210 oracle: a CCW's data address is relocatable when it is
# written as the location counter `*', exactly as when it names a label. K1 and
# K2 are the same construct twice, so the fixture is self-proving before IFOX00
# is asked; K4 is the control in the other direction -- a CCW whose target is in
# a DSECT gets NO entry, so a fix that drops the DSECT guard fails there.
#   main d81edda   RLD at 09, 19
#   IFOX00, this   RLD at 09, 11, 19
# The rc differs and the deck does not: IFOX00 returns 8 because it diagnoses K4
# (IFO158, name in a DSECT used in a relocatable address constant) and as370's
# CCW path issues no message at all. That message gap is cc370#211, measured
# separately -- ESD/TXT/RLD are byte-identical either way, which is what this
# loop compares.
# xsectrel is the #209 oracle: a difference of symbols in DIFFERENT control
# sections is not absolute -- it takes a SIGNED PAIR of relocation entries, and
# as370 emitted none because expr_val_full reports NET relocatability and the two
# sections cancel. C4 is what fixes the rule at one entry per UNIT of the tally
# rather than one per section; C2, C5 and C6 are the controls, two same-section
# differences that must produce nothing and a cancelling term that must leave
# exactly one.
#   main ea6163a   RLD 3 entries
#   IFOX00, this   RLD 6 entries, one of them flag 0F (negative)
# dcattr is the #218 oracle: dc_split took every apostrophe for a string quote,
# so an odd number of L'/K'/N'/T' attributes left it "inside a string" and the
# next top-level comma stopped separating -- `DC AL1(L'FLD),X'FF'' lost the
# X'FF' silently, at rc 0. G3 is the case that is right WITHOUT the fix (a
# leading X'FF' restores the parity), so a fixture built only from it proves
# nothing. G6 is the sharp control: a genuine string ending in L, which a fix
# that tests the CLOSING quote turns into an attribute and loses everything
# after.
#   main c4a0f19   07 | 0700 | FF07 | 07 | C1FF | D3FF
#   IFOX00, this   07FF | 0707 | FF07 | 07 | C1FF | D3FF
# equparen is the #221 oracle: a grouping parenthesis does not hide the leftmost
# term, so L' of `EQU (A+4)' is L'A. Three controls must stay 1 and each rules
# out a different wrong rule: `(4+S1)' (leftmost TERM, not first symbol),
# `(X'04'+S1)' (a self-defining term is not a symbol), and `( S1+4)' -- only the
# parenthesis is skipped, not the blank behind it. IFOX00 answers IFO234 for
# that last one and as370 says nothing, a message gap left alone here; the bytes
# agree, which is what this loop compares.
#   main 4373df2   01 01 01 01 01 01 01
#   IFOX00, this   07 01 07 07 03 01 01
# attre is the #223 oracle: attr_apos carried an E that IFOX00's own set (T L I
# S N K, ifnx1a.asm:4862) does not. E is a constant TYPE, so `DC E'1.0'' opened
# no string, the closing quote toggled the state on, and the remark joined the
# operand -- a comma in it then made a second constant and the statement was
# rejected. Note where this one fails without the fix: at the RC gate above, not
# at the byte compare, because as370 returned 8 where IFOX00 returns 0 with the
# same bytes. N2/N3/N4 are the controls, the same remark on an F and a C type
# and the same E constant with no comma; all three were accepted either way.
#   main 1e4fa80   rc 8, "Invalid type declared on DC/DS/DXD constant"
#   IFOX00, this   rc 0, no diagnostics
# cnop is the #231 oracle: CNOP aligns to a HALFWORD first, and the label
# addresses that point -- before the no-ops. The A-cons prove where: N1 must be
# 2, where 1 is before the halfword pad and 4 is after the no-ops, so both wrong
# rules fail here. N2 and N6 are the controls whose residue already matches and
# must produce NO no-op. Without the fix the label is undefined and the section
# is destroyed from the first CNOP on an odd counter: 64 no-ops, 128 bytes, rc 0.
#   main 6c3d966   N1/N2 undefined, next statement at x'81' (IFOX00: x'04')
#   IFOX00, this   labels at 2 / 0A / 12 / 1E / 2A / 30, deck identical
# aifcond is the #236 oracle: an AIF condition was cut at 126 characters while
# both call sites passed a 512-byte buffer, so a long one branched on a fragment
# ending mid-term. G6 is the case -- six terms, 137 characters joined. G4 is the
# control BELOW the threshold: four terms, 91 characters, correct on both
# binaries, so a fixture built only from it proves nothing. G2 is the control in
# the other direction, a condition that is TRUE and must stay true, which a fix
# that passes more text through but shifts the evaluation would break.
#   main 6dbb4bc   G4 G2 B6
#   IFOX00, this   G4 G2 G6
# eququote is the #238 oracle: a doubled apostrophe inside a C'..' self-defining
# term is ONE apostrophe, and three separate readers of that term collapsed `&&'
# while none collapsed the quote -- so `EQU C''''' was zero. Q3 is the control
# that was always right (`DC C''''), which is why the defect survived: the path
# people look at first works. Q4 protects the `&&' rule, Q5 the X branch, and Q6
# proves two pairs make two bytes rather than one.
#   main 6215f9f   00 C1 7D 50 7D 0000
#   IFOX00, this   7D C1 7D 50 7D 7D7D
# bitlen is the #240 oracle: a length modifier may be given in BITS, and as370's
# parse ended at the '.' with a length of zero -- the constant reserved nothing
# and every symbol after it was early, which is the mechanism behind #205. B1-BA
# pin the rules (packing, right padding, the duplication factor, and a non-bit
# operand flushing the run mid-statement); C1-C5 are the controls WITHOUT a bit
# modifier, which must come out byte for byte unchanged. The second half is what
# the 4831 identical modules depend on, and a fix that touched the ordinary
# length path would fail there rather than in the tree.
#   main 7bb7796   B1-BA emit nothing at all; C1-C5 correct
#   IFOX00, this   0012 8743 0010 F0 E9 A0 1110 00100003 10C120 (2 reserved) FF
# relop is the #243 oracle: blanks around a comparison operator are OPTIONAL and
# IBM's macros omit them -- AMODGEN(SYSEVENT) maps its whole mnemonic table with
# `AIF ('&EVENT'EQ'USERRDY').EOK'. The tokenizer did not end the operator token
# at the OPENING quote of its right operand, so EQ'USERRDY' became one token,
# no comparison was made and the AIF fell through. Q2 is the control that was
# always right (the same condition WITH blanks), so a fixture built from it
# passes on both binaries; Q5 is the control in the other direction -- L'FLD must
# not be split, the apostrophe there belongs to the attribute.
#   main f0e2a41   NOEQ OKSP NONE NOOR OKAT
#   IFOX00, this   OKEQ OKSP OKNE OKOR OKAT
# rxparen is the #247 oracle: a leading parenthesis in a machine operand is a
# GROUP, not the index pair. as370 read it as the subscript list and lost the
# displacement with it -- `L 15,(FIELD-BASE)(9)' came out 58F0 0000, at rc 0 and
# silent on both sides; `LA 1,(4-1)' took the 3 for a BASE REGISTER. Two changes
# were needed and the fixture proves both: the positional rule, and then the
# displacement evaluation (after the first alone the registers were right and
# every displacement was zero). R3/R6/R9 are the unparenthesised controls, and
# RA is the sharp one -- after the location counter `(9)' IS the index, so the
# positional rule must still tell the two apart.
#   main 89fb177   58F0 0000 | 58F0 0000 | 58F9 0010 | 4102 0000 | 4113 0000
#   IFOX00, this   58F9 0010 | 58F0 9010 | 58F9 0010 | 4110 0002 | 4110 0003
# lenattr is the #244 oracle: L' asks for the LENGTH ATTRIBUTE of the symbol and
# K' for the number of characters in the value; as370 answered both with strlen.
# SYS1.AMACLIB(ENQ) computes `&LEN SETA L'&P(&RN)' and writes it straight into
# the object one line later, so twelve modules differed in nothing else. L6 is
# the control that K' must NOT move, and L4/L5 pin the default of 1 for a symbol
# whose length is not resolvable -- an EQU to an absolute, and an unknown name.
# L7 is the same question without a variable, which needs its own read.
#   main 9ac48ad   N4 N2 N7 Y1 Y1 YK NLIT
#   IFOX00, this   Y4 Y2 Y7 Y1 Y1 YK YLIT
# contrem is the #250 oracle: a continuation card continues only what is not
# yet finished. Once the operand has ENDED, the next card continues the REMARK
# and belongs to no statement -- IFOX00 consumes it and discards its text.
# as370 truncated at the operand end and appended the card anyway: harmless on a
# literal, destructive on a VARIABLE, because the continuation extended the NAME
# (`&TYPNAM' + `GE' = `&TYPNAMGE', undefined, substituted to nothing).
# C2 rules out the obvious reading -- 'SHORT' leaves the card far short of the
# margin and is lost just the same, so it is the continuation and not the width.
# The comma control is not here: dcb, contattr, contparen, dc_types and
# sample8/9 ARE that case, and all five failed the first, over-broad attempt.
#   main 8ced9c4   0008 0012 40  (twice; the parameter gone, length still 18)
#   IFOX00, this   0008 0012 C'PROBLEM NUMBER' / C'SHORT'
# spmrr is the #252 oracle: split_fields fills only as many fields as the
# operand has, into a stack array the next statement reuses -- so an unwritten
# slot holds the PREVIOUS statement's text. SPM has one operand and the RR
# emitter reads two, so it took R2 from whatever RR came before it. SPM ALONE
# encodes correctly, which is why nothing found it: it needs a preceding RR, and
# `SR GRx,GRx' before `SPM GRx' is the standard way to clear the program mask.
# The two-operand RR instructions at the end are the controls that must not move.
#   main 48a07c0   048E 0488 0487 048E
#   IFOX00, this   0480 0480 0480 0480
# dcvlist is the #253 oracle: one operand may carry a LIST of values and each is
# a constant of its own, so `DC H'6,0,17,6,0'' is five halfwords. The fixed-point
# arm read the body with a single strtol and emitted the duplication factor's
# worth of the FIRST value. V3 and V4 are the controls that separate the two
# levels: 3H'7' multiplies the LIST, and X'1234',X'5678' is two OPERANDS -- a fix
# that split at the top level rather than inside the body fails there.
#   main 7c32f60   0006 | 0007 | 000700070007 | 12345678 | one fullword
#   IFOX00, this   0006000000110006 0000 | ... | 00000001 00000002 00000003
# scale is the #217 oracle: a scale modifier multiplies the nominal value by two
# to the power of the scale, so `DC FS3'1.25'' is 10. as370 read the value with
# strtol, which stops at the decimal point and knows nothing of the modifier.
# The corpus case is `DC FS28'6.2832'' -- two pi in the FORTRAN-syntax scientific
# routines -- x'6487FCB9' against x'00000006'. K3 is the control that separates
# rounding from truncation: 1.2 x 4 is 4.8 and IFOX00 writes 5, where 1.3 x 4
# would agree either way. K5/K6 have no modifier and must not move at all -- the
# scale path is entered only when one is present, which is what the tree gate
# then shows.
#   main daf53cc   00000006 0000000A 00000001 00000001
#   IFOX00, this   6487FCB9 0000000A 00000005 00000005
# setctype is the #257 oracle: T' is a term of a SETC expression as much as of a
# comparison, and only the comparison path had it -- `&T SETC T'&P'' assigned the
# four literal characters. The machinery was all there (the open-code look-ahead,
# is_selfdef, the letter table); the character path never reached it. The last
# three cases are the controls: an EQU and an unknown symbol both give U, and a
# self-defining number gives N, so reading only the type table fails on the
# number and testing only for digits fails on the EQU.
#   main b1d4af6   E3 nine times -- the letter T itself
#   IFOX00, this   F H C D X U A U N
# sublist is the #260 oracle: T' of a SUBLIST answers with the type attribute of
# its FIRST ELEMENT and does not descend further -- a first element that is
# itself a sublist gives U. as370 answered U for every sublist, so
# APVTMACS(HEXCNVT)'s `AIF (T'&OUT NE 'N').ERROR4' took the error path on a call
# as ordinary as `HEXCNVT (3),(2),4'. U3-U5 are the controls against "a sublist
# is always N", U6 against "take the first non-empty", and U9 is the one that
# fixes the rule: without it descent and non-descent are equally consistent,
# because (1,2) descended would also give N.
#   main 91ab753   U U C U N O N U U
#   IFOX00, this   N N C C N O N U U
# logop is the #262 oracle: a closing parenthesis ends a term as a closing quote
# does, so an operator abutting it is its own token. PVTMAC(GOIF1) writes
# `AIF (NOT(&B(1) AND &B(2) AND &B(3))OR '&ELSE' EQ '').C5' and without the rule
# the OR glued onto the group. The mirror of #243, which needed the same thing on
# the other side of the operator.
# The TRUTH VALUES are the trick: all three &B are 1 so NOT(...) is FALSE, and
# &ELSE is empty so the second operand is TRUE -- only then does the OR decide
# anything. With &B = 0 both operands are true and any parse answers true, which
# is how the first version of this fixture passed while the defect stood.
#   main f6f142c   NO1 OK2 OK3
#   IFOX00, this   OK1 OK2 OK3
# collate is the #264 oracle: a character comparison orders by the EBCDIC
# sequence, not the host's. The two disagree in exactly one place assembler
# source reaches -- LETTERS SORT BEFORE DIGITS in EBCDIC and after them in ASCII
# -- so letter-against-letter and digit-against-digit agree and C3/C4 were always
# right. That is why five instruments walked past it for two days. AMACLIB(DOM)
# tests a register with `AIF ('&MSG(1)' LE '12')' and `DOM MSG=(R1)' makes that
# 'R1' LE '12': true in EBCDIC, false here. C6/C7 hold the LENGTH rule from #189,
# which applies before content and must not move.
#   main d208259   N1 N2 Y3 Y4 N5 Y6 Y7
#   IFOX00, this   Y1 Y2 Y3 Y4 Y5 Y6 Y7
# usingmul is the #154 oracle: ONE USING may name up to 16 base registers, and
# they are assigned BY POSITION -- `USING D,11,12,10' gives 11 to D, 12 to
# D+4096, 10 to D+8192. as370 read the first register and dropped the rest, so a
# control block wider than 4096 bytes lost every field past the first range:
# IFO209 and a zeroed instruction, on 40 of the residual modules. BLSUPUT is the
# shape -- `USING BLSUPRAB,RB,RC', fields at x'E38' and x'28A' right through RB
# and the one at x'1144' gone.
# The registers here DESCEND, so an assignment sorted by register number gives
# HIGH the 11 and fails; and EDGE at D+4092 takes the 11 only because the ranges
# ASCEND -- were all three based at D, the #138 tie-break would hand it the 12.
# The last two cases are the counter-check on #177: keying by base register has
# to hold across a multi-register USING, for DROP and for replacement alike.
#   main acb4ebe   B01C  ....  ....  BFFC  9000  C01C   rc 8, two IFO209
#   IFOX00, this   B01C  C000  A000  BFFC  9000  C01C   rc 0
# stmtlen is the #153 oracle: FOUR bounds on the length of one statement, all
# silent. join_cont builds a joined statement into acc[8192] and everything
# downstream capped at about 1024 -- sysvar_sub cut every source line at 1022,
# parse() the operand at 1023, and &SYSLIST is materialised as ONE synthetic
# sublist whose buffer (and the subscript walker's copy of it) bounded the whole
# list rather than an element. Plus MAXSYSLIST at 64, a limit IFOX00 does not
# have. JTEXT's `DBV' call carries 86 positional operands and got 61: the tail
# simply was not there, K' of it was 0, and the macro generated nothing for it
# without a word. The call here is deliberately over 1022 characters so it tests
# all four at once -- &SYSLIST(70) is past the count bound, &SYSLIST(86) past the
# buffer -- and T2 is the short control that was always right.
#   main 9606b53   AL1(,)      rc 8, More than 64
#   IFOX00, this   X'4D58'     rc 0
# macbuf is the second #153 oracle: the fixed-size buffers of the macro path.
# A parameter value lived in 96 bytes, a prototype default in 40, a &SYSLIST
# element in 128 and a SETC in 96 -- four different numbers, none of them
# IFOX00's, and every one of them cut the value and reported the CUT length
# through K' without a word. IFOX00's limit is 255 and it says so past it:
# measured on the guest at 255 (clean), 256, 300 and 400 (IFO042 PARAMETER IN
# MACRO PROTOTYPE OR MACRO INSTRUCTION EXCEEDS 255 CHARACTERS, severity 8).
# C1's third value is the probe that the ELEMENT bound was separate from the
# parameter bound -- 95 against 127, two buffers, one construct.
# C3 is 150 and not 200 because a SETC is an assembler operation and gets TWO
# continuations (IFO069), where the macro calls in C1/C2 stand on four and are
# not bounded at all. That asymmetry is #78's, measured here by accident.
#   main 380a7c4   95,39,95   1,95,1    95
#   IFOX00, this   200,60,200 1,200,1   150
# dcvals is the #270 oracle: a DC address-constant operand held 32 nominal
# values and each value in 80 bytes, both silently. Past the 32nd the value was
# dropped, the location counter carried on early, and every later address in the
# section was wrong at rc 0.
# The bound is reachable in VALID source, which is the whole point: a DC is an
# assembler operation and gets two continuations, so its operand runs to about
# 168 characters -- room for some 55 short values. C1 puts 48 on three cards.
# C2 is one value of 89 characters, ten eight-character symbols; it is ten terms
# and not fifty because IFOX00 rejects an expression outside conditional assembly
# past 20 terms (IFO168), which the first version of this fixture found the hard
# way. L1 and L2 hold the generated LENGTH, so the check covers the counter and
# not only the bytes.
#   main f1334fc   L1=x'80'  D2=x'24' + Undefined symbol
#   IFOX00, this   L1=x'C0'  D2=x'37'
# substrcat is the #273 oracle: a SUBSTRING ends its term, so a term following
# it is concatenated with no period between them. The period separates two terms
# that would otherwise run together; after a closing parenthesis there is nothing
# to run together. as370 required it and dropped everything after the substring.
# IBM's USS macros pad a counter into a generated name exactly this way, and the
# counter is the part that was dropped -- so every generated block got the SAME
# name and every A(...) pointing at one resolved to the same place or to zero.
# C4's counter is four digits so the LENGTH of the second part varies: a fix that
# appends one character passes C1..C3 and fails here. C5 is the control, the same
# concatenation written WITH the period.
# Found through a third witness rather than through the oracle: IBM's shipped
# DLIB object and IFOX00 agree and as370 differs, which is the only way to settle
# a divergence where neither assembler says anything.
#   main 0e097a8   0000000 0000000 000000 0000   0009
#   IFOX00, this   00000000 00000007 00000042 00001234   0009
# usingexpr is the #275 oracle: a USING operand that BEGINS with `*' is an
# expression. `*' alone is the location counter; `*+8' is an expression that
# starts with it, and as370 tested only the first character, took the bare
# counter and threw the rest away. `USING *+8,R15' is the ordinary way to
# establish addressability past a BALR and its save area, so the base sat 8 bytes
# low and every displacement through that register came out 8 too high -- at rc 0
# with no diagnostic, in either assembler. IGG019GC and IGG019GD carry it and
# both become byte-identical.
# C3 goes the other way (*-24) so a fix that only handles `+' fails; C4 is the
# bare `*' and C5 a symbol expression, both of which were always right.
#   main 0e097a8   F008 F00C 0000(IFO209) D000 C000
#   IFOX00, this   F000 F004 E00C         D000 C000
# orglen is the #279 oracle: the counter an ORG SETS extends the section, not
# only the one it left behind. `ORG *+200' as a maintenance area at the end of a
# CSECT reserves the space and emits no TXT at all, and as370 tracked the section
# high-water mark from DS/DC alone -- so the section stayed 200 bytes short and
# the NEXT section moved forward by the same 200. Two wrong ESD entries and every
# reference into the second section wrong with them, at rc 0. IEHINITT carries it.
# T3 is a BACKWARD ORG, which must not shrink anything; T4 is the bare ORG, which
# already returned to the high-water mark and must stay where it was.
#   main 2a1505c   T1 len 000001  T2 at 000008
#   IFOX00, this   T1 len 0000C9  T2 at 0000D0
# sectlen is the #281 oracle: the section high-water mark has to be raised in
# PASS 1 too. It was raised by DS/DC and by put(), and put() runs only in pass 2,
# so a control section ending in MACHINE INSTRUCTIONS measured only to its last
# DS/DC when assign_origins() chained the next one -- and the two sections
# OVERLAPPED. Its own ESD length was right the whole time, because that comes
# from pass 2; only the next section's origin was wrong, which is why nothing
# reading one section's bytes could see it. AMASPZAP's AMASZDMP ends 332 bytes
# past its last DS and AMASZCON sat 332 bytes inside it. Its IMAGE goes from
# 7,577 differing bytes to none here; its deck still differs because the text is
# filed under the wrong ESD entry, which is a second defect in the same module.
# T3 ends on a CCW -- the same gap on a different path. T5 ends on a DC and is
# the control.
#   main 2a1505c   T1 len 000008  T2 at 000008
#   IFOX00, this   T1 len 00000C  T2 at 000010
# esdvsect is the #281 oracle: a CSECT whose name already has an ER from V().
# s->esdid feeds cur_sect_esdid and so the ESDID on the TXT card, and the
# assignment took the FIRST entry, resting on "a section's SD is registered
# before any ER for the same name". That stops being true the moment the name is
# REFERENCED first: `DC V(B)' ahead of `B CSECT' registers B's ER first, and B's
# whole TXT was filed under it. The ESD itself was right the whole time -- both
# entries present, right types, lengths and origin -- so only the TXT card named
# the wrong section, and no comparison of one section's bytes could see it.
# C is the control in the usual order, CSECT first and V() after; EXT is a real
# external that never becomes a section and whose ER must not move.
#   main 69f65dd   B's TXT under the ER's id
#   IFOX00, this   under the SD's
# ldentry is the #285 oracle: a DEFINITION outranks a lingering ER type. The
# sibling of #281 one level down -- there the ER won the section's ESDID, here it
# wins the symbol's TYPE. Every S_ER assignment is guarded by `if (!s->defined)',
# so the type is only ever set while the symbol is undefined, and it is never
# taken back when the definition arrives; assign_origins skipped such symbols, so
# the LD entry carried the section-relative value with no origin added.
# B sits in a LATER section -- only then do offset and origin separate at all --
# and the two numbers are deliberately different (24 against 16), so the result
# says WHICH of them is missing. D is an ENTRY with no V() ahead of it.
#   main 2c01e89   LD B 000018
#   IFOX00, this   LD B 000028
# endstop is the #288 oracle: END ends the assembly. Cards after the first END
# are not read, not listed and not assembled, and as370 read straight on.
# Not a technicality -- the MVSBLD tree has modules with a SECOND module's source
# appended behind the first END, and as370 assembled both into one object:
# ISTINCU7 came out with three control sections and 2,269 bytes where IFOX00 has
# one and 210, because IKJEGAPL is defined 1,100 cards past the END.
# B's section must be ABSENT from the ESD, not merely empty, which is why this
# one compares the whole deck rather than particular bytes.
#   main 87cdac3   two sections, 4 cards
#   IFOX00, this   one section, 3 cards
# emptyopnd is the #295 oracle: an operand that substitutes to NOTHING stays
# empty. as370 substituted the whole card and re-parsed it, and parse() cannot
# tell `INNER          REMARK HERE' -- an operand that vanished -- from a card
# written that way, so it read the remark's first word as the operand.
# BLSCAMMM calls `BLSCAMM1 &DYRB(2)         COUNT FLAGS1 ENTRIES' with a &DYRB
# that is not a sublist, so &DYRB(2) is null and the counting macro was handed the
# string COUNT: one element instead of none, a loop that must not run, and an
# MNOTE from a macro complaining about input we invented.
# The fixture reports K' rather than the text, so the DECK carries the answer.
#   main 500cefe   06 06 02   (K'REMARK, K'SECOND, K'AL)
#   IFOX00, this   00 00 02
# brmnem is the #298 oracle: the BR forms of BNP and BNM. Their BC forms were in
# the table and their BR counterparts were not -- the same masks, 13 and 11.
# IGG0203A and IGC0009D use them and as370 said `Undefined operation code' where
# IFOX00 is clean. The other ten BR forms stand beside them as the control: a mask
# transposed while adding these two shows up here rather than in the tree.
#   main b13ffa5   Undefined operation code - BNPR, BNMR
#   IFOX00, this   07DE 07BE
# subattr is the #300 oracle: an attribute apostrophe inside a SUBLIST. The
# sublist readers are the fourth pair of eyes on this syntax -- parse() got it in
# #182, split_card() in #183, dc_split() in #218 -- and never had it.
# `ENQ (SYSZPSWD,,E,L'JFCBDSNM,SYSTEM),MF=L' counted FOUR elements where IFOX00
# counts five, and element 4 came back as the single character `L' with the rest
# of the list swallowed, so the macro emitted SYSTEM as a symbol rather than as a
# scope. Measured through K'/N' and not the text: a value that itself contains an
# apostrophe takes apart the MNOTE you substitute it into, which is what the first
# version of this probe demonstrated instead of the defect.
#   main 621a8db   04 01 01 00
#   IFOX00, this   05 01 03 06
# genblank is the #302 oracle and the mirror of #295: a BLANK in a generated
# statement does not end the operand field. IFOX00 fixes the field boundaries on
# the MODEL card and substitutes into them, so a variable whose value is a blank
# stays inside the operand; as370 re-parsed the substituted text and stopped
# there. IFDCOM generates `IFDPF1 &V,&X,&Z,&S' with &Z a single blank, and as370
# lost BOTH remaining operands -- &S empty, an AIF on it took the wrong branch,
# and PARTITEM was never defined, reported 400 cards later as an undefined symbol.
# Same root as #295: the boundaries belong to the model card, not to the result.
#   main 30654d5   K'&C = 0, &D empty
#   IFOX00, this   K'&C = 1, &D = MVM22
# litdup is the #317 oracle: a duplication factor in a LITERAL. `=8X'0F'' is
# eight bytes, and as370 skipped the factor entirely -- one byte. That is not
# merely a short literal: the pool is segmented by lenalgn(size), so a literal of
# the wrong length also lands in the wrong SEGMENT and everything behind it
# moves. It is why sixteen modules came out N bytes short with every later
# displacement exactly N lower, and seven more had the right total length with
# the wrong order inside it.
# The fixture puts the factor on four types (X, C, F twice over) among plain
# literals, so both halves are visible: =8X'0F' has to be eight bytes AND has to
# sort into the 8-byte segment ahead of the =F' that was written before it.
#   main 2f90d47   deck differs, same total size
#   IFOX00, this   byte-identical
# repro is the #314 oracle. REPRO punches the card AFTER it into the object deck
# exactly as it stands, and does not assemble it; as370 had no such operation at
# all, so ICAPRTBL's three cards of IPL text drew `undefined operation code' and
# the module came out three cards short.
# The fixture asks the question the manual does not settle -- WHERE the card
# lands -- with one REPRO ahead of the CSECT and two among the DCs. IFOX00's
# answer: before the ESD block if it precedes the first control section, else
# between TXT cards, ENDING the one that is open. Three DCs that would share a
# single TXT card come out as three cards with a punched card between each pair,
# and the punched cards carry no sequence number nor advance the deck's.
#   f6b5123        3 x undefined operation code, cards missing
#   IFOX00, this   deck byte-identical, 8 cards in that order
# ovlattr is the #312 oracle, and the FOURTH place an attribute apostrophe has
# opened a quoted body: parse() (#149), join_cont() (#184), the sublist scanners
# (#300) and now has_overlong_term(). `L'' is an attribute and what follows it is
# a symbol; `X'' opens a body. Toggling on both desynchronises the state, and the
# next literal is what it reaches: in `CLC FLD-D(L'FLD,3),=X'FF00000000000000''
# the hex digits ended up outside any quote, sixteen alphanumerics read as one
# symbol, and IFO236 zeroed an instruction IFOX00 assembles (IGC0001I).
# Case 4 is the control that keeps the fix honest: X' must still quote, so
# `=X'FF00'' stays a body and not a symbol. A version that simply stopped
# toggling would pass cases 1 to 3 and fail this one.
#   f6b5123        IFO236, instruction zeroed
#   IFOX00, this   deck byte-identical
# selfdup is the #310 oracle: a DC's name field is defined BEFORE its operand is
# evaluated, so the duplication factor may name the statement's own label -- the
# pad-to-N idiom, `PATCH DC (4096-(PATCH-ERP1))X'00''. as370 evaluated the factor
# first, so the symbol was not yet defined: IFO231, then IFO217 for good measure,
# and no storage reserved. IGE0000I and IGE0002A write exactly that and IFOX00
# assembles both at rc 0.
# The fixture pads TWICE behind different run-ups, so a wrong answer cannot be a
# constant that happens to fit the first one, and it ends with DC AL1 of the two
# lengths and the total -- values, not just an rc.
#   main f1a3d30   IFO231 + IFO217, nothing reserved
#   IFOX00, this   PATCH x'0A', PATCH2 x'54', AL1 bytes 0A 14 30
# csect_resume{,2,3} are the #136 oracles: a resumed control section keeps its
# OWN counter, origins are chained from the FINAL lengths, and the END
# literal pool counts toward the first section's length before the later
# ones are placed behind it. Nothing else in this corpus resumes a section.
for s in sample1 sample2 sample3 sample4 sample5 sample6 sample7 sample8 sample9 sample10 \
         csect_resume csect_resume2 csect_resume3 \
         basereg basereg2 tattr_selfdef amp_subst subst_cont \
         amp_fold amp_selfdef len_attr equsect contparen attrapos rldlen \
         contattr cmprule absusing equlen esdself ssomit ssb1 entsd ccwstar \
         xsectrel dcattr equparen attre cnop aifcond eququote bitlen relop \
         rxparen lenattr contrem spmrr dcvlist scale setctype \
         sublist logop collate usingmul stmtlen macbuf setc_len95 dcvals \
         substrcat usingexpr orglen sectlen esdvsect ldentry \
         endstop emptyopnd brmnem subattr genblank selfdup ovlattr repro \
         litdup; do
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

# --- issue #144: T' of a symbol, answered by the open-code look-ahead --------
# The reference is a LISTING, not a deck: the fixture's macro emits OK per case
# and the IFOX listing shows 17 expansions, all OK. A deck comparison would not
# show which case failed, only that the bytes differ.
./as370 tests/tattr_symbol.s -a -o /dev/null 2>/dev/null \
    | grep -E "^[0-9A-F]{6} .*[0-9]+\+" | grep -oE "C'(OK |BAD)'" > /tmp/_tsym.$$
nok=$(grep -c "OK " /tmp/_tsym.$$ || true); nbad=$(grep -c "BAD" /tmp/_tsym.$$ || true)
if [ "$nok" = "17" ] && [ "$nbad" = "0" ]; then echo "tattr_symbol: OK (17/17 == IFOX00)"
else echo "tattr_symbol: MISMATCH ($nok ok, $nbad bad; IFOX00 has 17 ok, 0 bad)"; fail=1; fi
rm -f /tmp/_tsym.$$

# tattr_literal: the same attribute written OUT rather than reached through a
# macro parameter -- tattr_symbol only ever exercises T'&CC, and the evaluation
# took a different branch for a literal T'SF. Five cases, open code and macro
# body, IFOX00 rc=0.
./as370 tests/tattr_literal.s -a -o /dev/null 2>/dev/null \
    | grep -E "^[0-9A-F]{6} " | grep -oE "C'(OK |BAD)'" > /tmp/_tlit.$$
nok=$(grep -c "OK " /tmp/_tlit.$$ || true); nbad=$(grep -c "BAD" /tmp/_tlit.$$ || true)
if [ "$nok" = "5" ] && [ "$nbad" = "0" ]; then echo "tattr_literal: OK (5/5 == IFOX00)"
else echo "tattr_literal: MISMATCH ($nok ok, $nbad bad; IFOX00 has 5 ok, 0 bad)"; fail=1; fi
rm -f /tmp/_tlit.$$

# --- issue #149, second half: split_card() needs the same guard -------------
# The deck cannot see this one -- it is identical either way, which is why the
# check is on the LISTING. split_card() feeds the field-aware substitution, and
# the remarks field is left verbatim (#141). Without `inq ||' the closing quote
# of a string ending in an attribute letter reads as an attribute apostrophe, the
# operand field swallows the remark, and &X in the remark gets SUBSTITUTED --
# as370 then emits a generated statement where IFOX00 emits none.
# 'N' is an attribute letter, 'M' is not, so the second card is the control.
# Reference: tests/listref/ifox-listing-attrapos_remark.txt (IFOX00, rc 0,
# both remarks verbatim, no generated statement).
./as370 tests/attrapos_remark.s -a -o /dev/null > /tmp/_ar.$$ 2>&1
arbad=0
[ "$(grep -c "BEMERKUNG &X ENDE" /tmp/_ar.$$)" = "2" ] || arbad=1   # both remarks verbatim
grep -q "BEMERKUNG WERT ENDE" /tmp/_ar.$$ && arbad=1               # neither substituted
grep -qE "^[0-9A-F]{6} .*[0-9]+\+" /tmp/_ar.$$ && arbad=1          # no generated statement
if [ "$arbad" = "0" ]; then echo "attrapos_remark: OK (== IFOX00 -- remarks not substituted)"
else echo "attrapos_remark: MISMATCH (see /tmp/_ar.$$)"; fail=1; fi
rm -f /tmp/_ar.$$

# --- issue #177: USING is keyed by base register ----------------------------
# A second USING on a register REPLACES the first. The fixture places the
# replacement ABOVE the referenced symbol, so "replace" and "append" disagree:
# IFOX00 cannot resolve A and gives IFO209 + 0000 0000 at rc 8, where appending
# resolves it against the dead entry and assembles 5810 C000 in silence.
# The other two loads are the counter-check -- a replacement that reaches too
# far breaks them: L 2,HIGH must use the NEW domain, and L 3,A must work again
# after DROP + re-USING. Reference: tests/listref/ifox-listing-usingkey.txt.
./as370 tests/usingkey.s -a -o /dev/null > /tmp/_uk.$$ 2>&1
ukbad=0
grep -qE "^000004 0000 0000" /tmp/_uk.$$ || ukbad=1      # replaced: A unaddressable
grep -qE "^000008 5820 C000" /tmp/_uk.$$ || ukbad=1      # the new domain resolves
grep -qE "^00000C 5830 C000" /tmp/_uk.$$ || ukbad=1      # DROP + re-USING resolves
grep -q "Addressability error" /tmp/_uk.$$ || ukbad=1    # and it is diagnosed
if [ "$ukbad" = "0" ]; then echo "usingkey: OK (== IFOX00 -- USING replaces per register)"
else echo "usingkey: MISMATCH (see /tmp/_uk.$$)"; fail=1; fi
rm -f /tmp/_uk.$$

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
# building). Section length, TXT and message texts stay the oracle's.
#
# The SEVERITY of a discarded statement was as370's own choice: IFOX00 gives the
# harmless case and the statement-losing one the same 4, and as370 returned 8 for
# the second. Under `as370 == IFOX00' meaning the deck AND the return code that
# cost eight modules whose decks are byte-identical, so as of 2026-09-09 the
# default is IFOX00's 4 and the guard is `--strict-cont'. Both are checked here,
# because a fixture that pins only the default cannot tell the flag from a no-op.
./as370 --strict-cont tests/cont72.s -o /dev/null >/dev/null 2>&1
if [ $? != 8 ]; then echo "cont72: --strict-cont must still return 8"; fail=1; fi
./as370 tests/cont72.s -o /tmp/_c72.obj >/tmp/_c72.out 2>&1; rc72=$?
n26=$(grep -c 'IFO026' /tmp/_c72.out); n69=$(grep -c 'IFO069' /tmp/_c72.out)
nlost=$(grep -c '^ ERROR: This card was consumed' /tmp/_c72.out)
hex=$(od -An -tx1 /tmp/_c72.obj | tr -d ' \n')
if [ $rc72 != 4 ]; then
    echo "cont72: expected RC 4 (IFOX00's severity for a discarded statement), got $rc72"; fail=1
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
    echo "cont72: OK (8 bytes and IFOX00's messages; rc 4 by default, 8 under --strict-cont)"
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
# --strict-cont: this case is about the discarded statement still being COUNTED
# past the print cap, not about its severity. The severity default followed
# IFOX00 to 4 on 2026-09-09; the flag keeps this assertion testing what it was
# written to test rather than re-testing the new default.
./as370 --strict-cont /tmp/_cap.s -o /tmp/_cap.obj >/tmp/_cap.out 2>&1; rccap=$?
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
# --- issue #82: an undefined symbol is IFO188, and the instruction is zeroed --
# Checked against tests/listref/ifox-listing-undefsym.txt, IFOX00's listing for
# this fixture (JOB02870). Both halves matter:
#
#     000000 0000 0000            8          BE    NOWHERE
#     000004 0000 0000            9          LH    3,NOSUCH(,7)
#     000008 0000 0000 0000      10          MVC   FIELD-BASE(8,2),0(3)
#
# The MESSAGE (IFO188, severity 8, erms.asm:193 / jermsgcd.asm SEV188) and the
# BYTES. as370 used to keep the opcode and zero only the operands, which is the
# worse half: IFOX00's all-zero instruction is an invalid opcode and S0C1s the
# moment it is reached, while ours RAN -- a branch to address 0, a load from
# base+0, an MVC into offset 0 of whatever the base register held. That silence
# is how nsf370's two modules lost a DCBD, two EQUs and a whole instruction to
# #72's continuation rule without one diagnostic between them.
#
# The literal is the case that must NOT be zeroed: IFOX assembles `L 4,=A(NOVAL)`
# as 5840 F018 -- the literal resolves to its pool address, which is defined --
# and flags NOVAL against the pool statement instead. So the deck's 14 zero bytes
# are followed immediately by an intact L, which is what the first grep asserts.
#
# tests/undefsym.s is an ORACLE INPUT: IFOX00's listing prints its five comment
# cards verbatim and numbers every statement from them, so the fixture and the
# listing move together or not at all -- editing one alone shifts every statement
# number asserted below. Re-capture with tests/oracle/capture.py, never edit in
# place. And keep every card inside column 71: a sixth card was tried while
# writing this, reached column 72, and under #72's continuation rule ate
# `UNDEFSYM CSECT` outright -- in the fixture for the diagnostic about symbols
# lost to exactly that rule.
#
# Two deliberate divergences from the oracle, both benign:
#  - IFOX flags NOVAL at stmt 14 (the generated pool statement); as370 flags it
#    at stmt 11, the statement that WROTE the literal, the way IFO158 already
#    does (dsect_adcon above). as370's listing renders the pool line but has no
#    lines[] entry for it to hang a diagnostic on.
#  - (was: IFOX says NUMBER OF STATEMENTS FLAGGED = 4 where as370 said 5, because
#    stmt 10 raises two messages and as370's counter counted messages. Fixed in
#    #88 -- both say 4 now, which is what the assertion below pins.)
./as370 tests/undefsym.s -o /tmp/_u82.obj >/tmp/_u82.out 2>&1; rc82=$?
hex=$(od -An -tx1 /tmp/_u82.obj | tr -d ' \n')
n188=$(grep -c 'Undefined symbol in line' /tmp/_u82.out)
if [ $rc82 != 8 ]; then
    echo "undefsym: expected RC 8 (IFO188 is severity 8), got $rc82"; fail=1
elif [ "$n188" != 5 ]; then
    echo "undefsym: expected 5 IFO188 messages, got $n188"; fail=1
elif ! grep -q 'line 8 - NOWHERE'  /tmp/_u82.out ||
     ! grep -q 'line 9 - NOSUCH'   /tmp/_u82.out ||
     ! grep -q 'line 10 - FIELD'   /tmp/_u82.out ||
     ! grep -q 'line 10 - BASE'    /tmp/_u82.out ||
     ! grep -q 'line 11 - NOVAL'   /tmp/_u82.out; then
    echo "undefsym: the five messages do not name NOWHERE/NOSUCH/FIELD/BASE/NOVAL at their statements"; fail=1
elif ! grep -q '4 Statements Flagged' /tmp/_u82.out; then
    echo "undefsym: expected the oracle's 4 flagged statements (stmt 10 raises two of the five messages)"; fail=1
elif ! echo "$hex" | grep -q "00000000000000000000000000005840f018"; then
    echo "undefsym: BE/LH/MVC are not all-zero, or the literal reference was zeroed with them"; fail=1
elif echo "$hex" | grep -q "47800000" || echo "$hex" | grep -q "48307000" ||
     echo "$hex" | grep -q "d20720003000"; then
    echo "undefsym: an opcode survived -- the instruction runs instead of program-checking"; fail=1
elif ! echo "$hex" | grep -q "000100010c000014"; then
    echo "undefsym: the RLD is not the single DEFHERE entry -- an undefined term invented a relocation"; fail=1
else
    echo "undefsym: OK (IFO188 x5 at RC 8; BE/LH/MVC zeroed, the literal reference intact, one RLD entry)"
fi
rm -f /tmp/_u82.obj /tmp/_u82.out
# The other side of #82: everything an operand may hold that LOOKS like a symbol
# and is not. The scanner that decides "zero this instruction" is lexical, so a
# self-defining term or an attribute prefix left unhandled would read as an
# undefined symbol named X, C, B or L and zero a perfectly good instruction --
# `MVI FLAG,X'40'` is the shape that would break first. The literal skip is here
# too, and every symbol is a FORWARD reference, which is what proves the
# diagnostic stays silent in pass 1 where a not-yet-defined symbol is legal.
{ printf 'UNDEFOK  CSECT\n         USING UNDEFOK,15\n'
  printf '         MVI   FLAG,X\04740\047\n'
  printf '         CLI   FLAG,C\047A\047\n'
  printf '         BC    B\0471111\047,SKIP\n'
  printf '         MVC   FIELD(L\047FIELD),FIELD\n'
  printf '         L     1,=A(FIELD)\n'
  printf 'SKIP     BR    14\nFLAG     DS    X\nFIELD    DS    CL8\n         END\n'; } > /tmp/_uok.s
./as370 /tmp/_uok.s -o /tmp/_uok.obj >/tmp/_uok.out 2>&1; rcok=$?
hexok=$(od -An -tx1 /tmp/_uok.obj | tr -d ' \n')
if [ $rcok != 0 ]; then
    echo "undefsym: the self-defining-term control does not assemble clean (RC $rcok)"
    sed 's/^/          /' /tmp/_uok.out; fail=1
elif ! echo "$hexok" | grep -q "9240f01895c1f01847f0f016d207f019f0195810f02807fe"; then
    echo "undefsym: the control's bytes moved -- X'40'/C'A'/B'1111'/L'FIELD'/=A() no longer assemble as they did"; fail=1
else
    echo "undefsym: OK (X'..'/C'..'/B'..'/L'..'/=A() and forward references stay clean at RC 0)"
fi
rm -f /tmp/_uok.s /tmp/_uok.obj /tmp/_uok.out
# --- issue #94: &SYSLIST(n,m) reaches INSIDE a sublist operand ---------------
# &SYSLIST(n) is the n'th positional operand; &SYSLIST(n,m) is the m'th element
# of that operand's sublist. as370 evaluated the whole subscript text as one
# expression -- eval_seta("1,1") stops at the comma and yields 1 -- so the second
# subscript was dropped and the reference returned the operand ENTIRE, parentheses
# included. Used as a name, the generated statement carried `(ALPHA,8,GAMMA)` and
# the module died of an over-long name field: a diagnostic correct about what it
# saw and pointing nowhere near the cause.
#
# tests/ref/syslist.obj and tests/listref/ifox-listing-syslist.txt are IFOX00's
# deck and listing for this fixture (JOB02901, RC 0). The fixture probes both
# operand shapes on purpose, because the non-sublist one decides whether the
# per-level substitution needs a special case:
#
#   operand 1 = (ALPHA,8,GAMMA)   (1,1)=ALPHA  (1,2)=8  (1,3)=GAMMA
#   operand 2 = BETA              (2,1)=BETA   (2,2)=NULL
#
# It does not: sub_elem already returns a value with no leading '(' for index 1
# and nothing for index 2, which is exactly what the guest does.
#
# The fixture also needs LCLA/LCLC. IFOX rejects an undeclared SET symbol with
# IFO006 (22 statements flagged on the first capture attempt) where as370 accepts
# it -- a separate leniency, not this issue.
./as370 tests/syslist.s -o /tmp/_s94.obj >/tmp/_s94.out 2>&1; rc94=$?
./as370 tests/syslist.s -a -o /dev/null >/tmp/_s94.lst 2>/dev/null
s94sz=$(wc -c < /tmp/_s94.obj); r94sz=$(wc -c < tests/ref/syslist.obj)
if [ $rc94 != 0 ]; then
    echo "syslist: expected RC 0, got $rc94"; sed 's/^/          /' /tmp/_s94.out; fail=1
elif grep -q '(ALPHA,8,GAMMA) EQU' /tmp/_s94.lst || grep -q "C'/(ALPHA" /tmp/_s94.lst; then
    # the bug's own signature, not the source line: the CALL statement legitimately
    # reads `SUBL (ALPHA,8,GAMMA),BETA`, so only the GENERATED lines can say this
    echo "syslist: a sublist operand was substituted whole -- the second subscript is being dropped"; fail=1
elif ! grep -q 'ALPHA    EQU   8' /tmp/_s94.lst; then
    echo "syslist: &SYSLIST(1,1)/(1,2) did not yield ALPHA and 8"; fail=1
elif [ "$s94sz" != "$r94sz" ]; then
    echo "syslist: deck $s94sz bytes against IFOX00's $r94sz"; fail=1
else
    n94=$(( (r94sz / 80 - 1) * 80 ))
    head -c "$n94" /tmp/_s94.obj > /tmp/_s94a.$$; head -c "$n94" tests/ref/syslist.obj > /tmp/_s94b.$$
    if cmp -s /tmp/_s94a.$$ /tmp/_s94b.$$; then
        echo "syslist: OK (== IFOX00: GAMMA, BETA, the null element, and ALPHA EQU 8)"
    else
        echo "syslist: deck differs from IFOX00 before the END card"; fail=1
    fi
    rm -f /tmp/_s94a.$$ /tmp/_s94b.$$
fi
rm -f /tmp/_s94.obj /tmp/_s94.out /tmp/_s94.lst
# The balanced scan, on its own: a subscript may carry its own parentheses, and
# strchr(')') would then cut at the wrong bracket. &SYSLIST((&I+1),1) with &I=1
# must reach operand 2's first element.
{ printf '         MACRO\n&NAME    SUBI  &P1,&P2\n         LCLA  &I\n         LCLC  &V\n'
  printf '&I       SETA  1\n'
  printf '&V       SETC  \047&SYSLIST((&I+1),1)\047\n'
  printf 'NESTED   DC    C\047/&V/\047\n         MEND\n'
  printf 'T        CSECT\n         SUBI  (A,1),(DELTA,2)\n         END\n'; } > /tmp/_s94n.s
./as370 /tmp/_s94n.s -o /tmp/_s94n.obj >/tmp/_s94n.out 2>&1; rcn=$?
hexn=$(od -An -tx1 /tmp/_s94n.obj | tr -d ' \n')
if [ $rcn != 0 ]; then
    echo "syslist_nested: expected RC 0, got $rcn"; fail=1
elif ! echo "$hexn" | grep -q "61c4c5d3e3c161"; then
    echo "syslist_nested: a parenthesised subscript truncated the expression -- expected C'/DELTA/'"; fail=1
else
    echo "syslist_nested: OK (a parenthesised subscript is scanned to its own closing bracket)"
fi
rm -f /tmp/_s94n.s /tmp/_s94n.obj /tmp/_s94n.out
# --- issue #93: a parenthesised duplication factor on DC/DS ------------------
# Assembler XF takes an absolute expression in parentheses wherever a decimal
# self-defining term may stand as a duplication factor (xdcds.asm:110 --
# CLI CHAR1,JLPARN / SEE IF EXPRESSION). as370 read the '(' as the constant's
# TYPE, rejected the statement, and reserved nothing -- so every symbol after it
# in the section moved. 126 modules of a real IBM MVS source tree use it; the
# shape is a compiler-generated patch area sized over the distance between two
# labels.
#
# tests/listref/ifox-listing-dupfac.txt is IFOX00's listing for this fixture
# (JOB02900) and settles every case, including the two that decide the design:
#
#   (0)X'00'      LEGAL and silent -- reserves nothing, no diagnostic
#   forward ref   IFO231 + IFO217 + IFO206, and reserves nothing
#
# The forward-reference rule is what makes the construct implementable at all in
# two passes: by pass 2 the symbol IS defined, so a pass-2 re-evaluation would
# allocate where pass 1 allocated nothing and the location counter would move
# between the passes. Because IFOX rejects it outright, pass 1's verdict can
# simply be remembered (dup_rejected()).
#
# IFO217 is severity 12 (jermsgcd.asm SEV217) where IFO231 and IFO206 are 8, so
# ONE forward reference takes the assembly to RC 12. That is the oracle's RC and
# it is reproduced rather than flattened to 8.
#
# No deck oracle: IFOX00 does not punch at severity 12, so the listing is the
# reference here. It carries the LOC and OBJECT CODE columns, which is precisely
# what a duplication factor decides.
./as370 tests/dupfac.s -o /tmp/_d93.obj >/tmp/_d93.out 2>&1; rc93=$?
hex93=$(od -An -tx1 /tmp/_d93.obj | tr -d ' \n')
if [ $rc93 != 12 ]; then
    echo "dupfac: expected RC 12 (IFO217 is severity 12), got $rc93"; fail=1
elif ! echo "$hex93" | grep -q "4000003a"; then
    echo "dupfac: section length is not 0x3A -- the duplication factors did not size as IFOX00's"; fail=1
elif ! echo "$hex93" | grep -q "4000002840400009"; then
    echo "dupfac: no 9-byte TXT at 000028 -- CALCDC's 5 and SIMPLEDC's 4 did not both land"; fail=1
elif ! echo "$hex93" | grep -q "4000003640400004"; then
    echo "dupfac: no 4-byte TXT at 000036 -- the plain decimal control moved"; fail=1
elif ! grep -q 'IFO231) - FWDEND in line 13' /tmp/_d93.out ||
     ! grep -q 'IFO217) in line 13'          /tmp/_d93.out ||
     ! grep -q 'IFO206) in line 13'          /tmp/_d93.out ||
     ! grep -q 'IFO206) in line 15'          /tmp/_d93.out; then
    echo "dupfac: the four messages are not IFO231+IFO217+IFO206 on stmt 13 and IFO206 on stmt 15"; fail=1
elif grep -q 'in line 11' /tmp/_d93.out; then
    echo "dupfac: (0) was flagged -- a zero duplication factor is legal and reserves nothing"; fail=1
elif ! grep -q '2 Statements Flagged' /tmp/_d93.out; then
    echo "dupfac: expected the oracle's 2 flagged statements over 4 messages"; fail=1
else
    echo "dupfac: OK (expression/(0)/decimal size as IFOX00; forward ref and negative rejected at RC 12)"
fi
rm -f /tmp/_d93.obj /tmp/_d93.out
# The balanced scan, on its own. The common shape carries an inner parenthesis,
# so a strchr(')') would cut the expression at the WRONG bracket and value it at
# whatever the truncated text yields -- silently, since the result is still a
# number. A flat factor and a nested one must size the same here.
{ printf 'BAL93    CSECT\nWSTART   DS    0H\n         DS    CL32\nWEND     DS    0H\n'
  printf 'NESTED   DC    ((WEND-WSTART)/8)X\04700\047\n'
  printf 'FLAT     DC    (4)X\04700\047\n         END\n'; } > /tmp/_d93b.s
./as370 /tmp/_d93b.s -o /tmp/_d93b.obj >/tmp/_d93b.out 2>&1; rcb=$?
hexb=$(od -An -tx1 /tmp/_d93b.obj | tr -d ' \n')
if [ $rcb != 0 ]; then
    echo "dupfac_nested: expected RC 0, got $rcb"; sed 's/^/          /' /tmp/_d93b.out; fail=1
elif ! echo "$hexb" | grep -q "40000028"; then
    echo "dupfac_nested: section is not 0x28 -- 4 nested + 4 flat bytes did not both land"; fail=1
else
    echo "dupfac_nested: OK (an inner parenthesis does not truncate the expression)"
fi
rm -f /tmp/_d93b.s /tmp/_d93b.obj /tmp/_d93b.out
# --- issue #88: the summary counts STATEMENTS flagged, not messages ----------
# IFOX00's ERRORTN (ifnx6b.asm:443) holds LSTMTNO, a single fullword initialised
# to -1, and increments ERRQTY only when the statement number differs from the
# immediately preceding one -- so one statement with three diagnostics is one
# flagged statement. as370 used to sum the per-recorder message totals.
#
# Four things have to hold at once, and each has its own trap.
#
# (a) THE PRINT CAP MUST NOT REACH THE COUNT. Every one of the ten recorders
#     still stops its printed list at 128 entries. 200 over-length operand terms
#     are 200 flagged statements; before #88 the summary said 128, silently --
#     the same defect bce38d8 fixed for the continuation recorder, in the ten
#     that were left.
{ printf 'CAPPED   CSECT\n         USING CAPPED,15\n'
  i=0; while [ $i -lt 200 ]; do printf '         L     1,LONGSYMBOL%03d\n' $i; i=$((i + 1)); done
  printf '         BR    14\n         END\n'; } > /tmp/_f88a.s
./as370 /tmp/_f88a.s -o /dev/null >/tmp/_f88a.out 2>&1; rcA=$?
if [ $rcA != 8 ]; then
    echo "flagged_cap: expected RC 8 (IFO236), got $rcA"; fail=1
elif ! grep -q '200 Statements Flagged' /tmp/_f88a.out; then
    echo "flagged_cap: the count did not survive the 128-entry print cap: $(grep 'Assembler Done' /tmp/_f88a.out)"; fail=1
else
    echo "flagged_cap: OK (200 flagged statements counted, 128 printed)"
fi
# (b) TWO RECORDERS, ONE STATEMENT, ONE COUNT. A statement continued onto a card
#     with non-blanks in columns 1-15 (IFO026) that ALSO references an undefined
#     symbol (IFO188) is ONE flagged statement -- the two diagnostics reach the
#     summary through different key spaces (the continuation one is raised while
#     cards are joined, before lines[] exists) and used to be added up.
{ printf 'T        CSECT\n         USING T,15\n'
  printf '%-71sX\n' '         MVC   FIELD(8),'
  printf 'JUNK             0(3)\n'
  printf '         BR    14\n         END\n'; } > /tmp/_f88b.s
./as370 /tmp/_f88b.s -o /dev/null >/tmp/_f88b.out 2>&1
if ! grep -q '1 Statement Flagged' /tmp/_f88b.out; then
    echo "flagged_overlap: one statement in both diagnostic spaces counted more than once: $(grep 'Assembler Done' /tmp/_f88b.out)"; fail=1
else
    echo "flagged_overlap: OK (continuation + undefined symbol on one statement = 1)"
fi
# (c) AND THE RECONCILIATION MUST NOT OVER-REACH. The card number is the only key
#     the two spaces share, and a LIBRARY MEMBER's card numbers are member-
#     relative: member card 4 and primary-source card 4 are different statements.
#     Subtracting on the number alone turns this two-statement module into one --
#     an UNDER-count, which hides a diagnostic, so it is the worse direction.
mlib88=/tmp/_ml88.$$
mkdir -p "$mlib88"
{ printf '         MACRO\n&L       BADM\n'
  printf '%-71sX\n' '&L       MVC   0(8,1),'
  printf 'JUNK             0(2)\n'
  printf '         MEND\n'; } > "$mlib88/badm.macro"
{ printf 'T        CSECT\n         USING T,15\n'
  printf 'LBL      BADM\n'
  printf '         L     1,NOSUCH\n'
  printf '         BR    14\n         END\n'; } > "$mlib88/a.s"
./as370 "$mlib88/a.s" -I "$mlib88" -o /dev/null >"$mlib88/a.out" 2>&1
if ! grep -q '2 Statements Flagged' "$mlib88/a.out"; then
    echo "flagged_libcard: a member-relative card number was merged with a primary-source one: $(grep 'Assembler Done' "$mlib88/a.out")"; fail=1
else
    echo "flagged_libcard: OK (member card 4 and source card 4 stay two statements)"
fi
# (d) THE KNOWN RESIDUAL, PINNED AS A TRIPWIRE -- NOT A PASSING FEATURE.
#     One GENERATED statement that is both badly continued and references an
#     undefined symbol. IFOX00 counts 1; as370 counts 2, because the continuation
#     diagnostic carries a member-relative card number that names no statement in
#     this numbering, so it cannot be reconciled with the lines[] one.
#
#     Closing it needs the origin (member, card) of every generated line threaded
#     through the macro expander -- issue #91. When that lands, this case becomes
#     1 and the assertion below fails, which is the point: it brings whoever does
#     it here instead of leaving the number to be discovered.
#
#     Measured: 0 of 835 ecosystem modules produce a library-member continuation
#     diagnostic at all -- #81 (a library macro is read to its MEND, and no card
#     further) removed the last of them.
mlib89=/tmp/_ml89.$$
mkdir -p "$mlib89"
{ printf '         MACRO\n&L       BOTHM\n'
  printf '%-71sX\n' '&L       MVC   FIELD(8),'
  printf 'JUNK             0(2)\n'
  printf '         MEND\n'; } > "$mlib89/bothm.macro"
{ printf 'T        CSECT\n         USING T,15\n'
  printf 'LBL      BOTHM\n'
  printf '         BR    14\n         END\n'; } > "$mlib89/a.s"
./as370 "$mlib89/a.s" -I "$mlib89" -o /dev/null >"$mlib89/a.out" 2>&1
if grep -q '1 Statement Flagged' "$mlib89/a.out"; then
    echo "flagged_libmac: #91 looks implemented -- this tripwire should now assert 1, not 2"; fail=1
elif grep -q '2 Statements Flagged' "$mlib89/a.out"; then
    echo "flagged_libmac: OK (documented residual #91: a library-member continuation counts on its own, 2 for IFOX00's 1)"
else
    echo "flagged_libmac: neither the documented 2 nor the correct 1: $(grep 'Assembler Done' "$mlib89/a.out")"; fail=1
fi
rm -rf /tmp/_f88a.s /tmp/_f88a.out /tmp/_f88b.s /tmp/_f88b.out "$mlib88" "$mlib89"

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
# --strict-cont for the same reason as diag_cap: what this asserts is that a
# column-72 comment INSIDE a library macro definition eats the model statement
# and is flagged for it, not what severity the flag carries.
./as370 --strict-cont "$mlib/b.s" -I "$mlib" -o "$mlib/b.obj" >"$mlib/b.out" 2>&1; rcB=$?
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

# --- issue #305: a COPY'd card inside a macro is not a model statement -------
# #302 made a BLANK in a generated statement stop ending the operand, because
# IFOX00 fixes the field boundaries on the MODEL card and substitutes into them.
# It read that condition off LF_GEN -- "this line came out of a macro expansion"
# -- and a card a COPY brings INTO an expansion satisfies it without being a
# model statement at all: nothing is substituted into it and no model card cut
# its remark off. So the remark joined the operand, and a remark containing a
# COMMA then split into further operands, each beginning with a blank where the
# constant type belongs. JCOMMON's `JLVTMDT DS 0CL24  ASM LEVEL, TIME, DATE'
# gave two of them; three IFNX modules IFOX00 assembles clean went to RC 8.
#
# The fixture asserts BOTH rules, because a fix for either one alone passes half
# of it and the two live one line apart:
#   vor #304 (e28d86e)   rc 8 -- the substituted blank ended the operand
#   main     (7a0cd90)   rc 8 -- the COPY'd remark became two bad operands
#   both correct         rc 0
# Only a remark holding a comma shows the second, which is why it reached three
# modules and not three hundred -- and why the member below carries two.
cpm=/tmp/_cpyrem.$$
mkdir -p "$cpm"
printf '%-71s\n' \
  'GRP      DS    0CL24                    SIZE, TIME AND DATE' \
  'GRPA     DS    CL10                     FIRST PART' \
  'GRPB     DS    CL14                     SECOND, AND LAST' > "$cpm/cpyrem"
# it is only a fixture while the remarks really do carry a comma
if [ "$(grep -c ',' "$cpm/cpyrem")" != 2 ]; then
    echo "copyrem: BROKEN FIXTURE (the COPY'd remarks carry no comma)"; fail=1
fi
printf '%-71s\n' \
  '         MACRO' \
  '         GENC' \
  '         COPY  CPYREM' \
  '         MEND' \
  '         MACRO' \
  '         GENB  &P' \
  '         LCLC  &Z' \
  "&Z       SETC  ' '" \
  '         INNER &P,&Z,LAST' \
  '         MEND' \
  '         MACRO' \
  '         INNER &A,&B,&C' \
  "         AIF   ('&C' EQ 'LAST').OK" \
  "         MNOTE 8,'SUBSTITUTED BLANK ENDED THE OPERAND'" \
  '.OK      ANOP' \
  "GOT&A    DC    C'&C'" \
  '         MEND' \
  'T        CSECT' \
  '         GENC' \
  '         GENB  X' \
  '         DC    AL1(GRPA-GRP)' \
  '         DC    AL1(GRPB-GRP)' \
  '         DC    AL1(GRPB+14-GRP)' \
  '         END' > "$cpm/a.s"
./as370 "$cpm/a.s" -I "$cpm" -o "$cpm/a.obj" >"$cpm/a.out" 2>&1; rcC=$?
if grep -q 'Invalid type declared' "$cpm/a.out"; then
    echo "copyrem: the COPY'd card's remark joined the operand (#305)"; fail=1
elif grep -q 'SUBSTITUTED BLANK' "$cpm/a.out"; then
    echo "copyrem: a substituted blank ended the operand (#302 regressed)"; fail=1
elif [ $rcC != 0 ]; then
    echo "copyrem: rc $rcC, expected 0"; cat "$cpm/a.out"; fail=1
elif ! od -An -tx1 "$cpm/a.obj" | tr -d ' \n' | grep -q 000a18; then
    echo "copyrem: GRPA-GRP / GRPB-GRP / the group length are not 0, 10, 24"; fail=1
else
    echo "copyrem: OK (a COPY'd remark stays a remark; a substituted blank stays in the field)"
fi
rm -rf "$cpm"

# --- issue #307: a COPY'd card inside a macro is substituted, and from the ----
# ---              enclosing expansion's variables ----------------------------
# The other half of #305. IFOX00 splices a COPY'd member into the macro body in
# its edit phase, so the member's cards are model statements of THAT expansion:
# their variable symbols are substituted, and their conditional assembly reads
# the same variables. as370 expanded COPY lazily, substituted nothing into such
# a card, and evaluated its AIF against open code.
#
# ICOMMON's `&COMPNM.X4V01  CONTAINS  EVAL' reached CONTAINS with the LITERAL
# name. CONTAINS stores it in a global array; GOTO takes `'&X0(1)'(4,5)' of it,
# which of `&COMPNM.X4V01' is `MPNM.'; and `L R12,MPNM.' was reported as an
# undefined symbol some 900 statements later, in seven IFNX modules.
#
# The fixture writes the SAME call twice -- once in the macro body, once in a
# member the body COPYs, behind an AIF on the macro's own parameter -- and
# CHECK requires both to have produced ABCCPY01. The equality alone would not
# do: if neither substituted, both would hold `&G.CPY01' and agree. The name is
# asserted, so a wrong answer cannot pass by being wrong twice.
#   main b799ae0    COPY NAME IS ><   (the AIF never saw &SEL)   rc 8
#   this            rc 0
cpv=/tmp/_cpysub.$$
mkdir -p "$cpv"
printf '%-71s\n' \
  "         AIF   ('&SEL' NE 'YES').SKIP" \
  '&G.CPY01 INNER FROMCOPY' \
  '.SKIP    ANOP' > "$cpv/cpysub"
printf '%-71s\n' \
  '         MACRO' \
  '&P       INNER &D' \
  '         GBLC  &SAWC,&SAWB' \
  "         AIF   ('&D' EQ 'FROMCOPY').C" \
  "&SAWB    SETC  '&P'" \
  '         MEXIT' \
  '.C       ANOP' \
  "&SAWC    SETC  '&P'" \
  '         MEND' \
  '         MACRO' \
  '         CHECK' \
  '         GBLC  &SAWC,&SAWB' \
  "         AIF   ('&SAWC' EQ 'ABCCPY01').N1" \
  "         MNOTE 8,'COPY NAME IS >&SAWC<'" \
  ".N1      AIF   ('&SAWB' EQ 'ABCCPY01').N2" \
  "         MNOTE 8,'BODY NAME IS >&SAWB<'" \
  '.N2      ANOP' \
  '         MEND' \
  '         MACRO' \
  '         OUTER &SEL' \
  '         GBLC  &G' \
  "&G       SETC  'ABC'" \
  '         COPY  CPYSUB' \
  '&G.CPY01 INNER INBODY' \
  '         MEND' \
  'T        CSECT' \
  '         OUTER YES' \
  '         CHECK' \
  '         END' > "$cpv/a.s"
./as370 "$cpv/a.s" -I "$cpv" -o "$cpv/a.obj" >"$cpv/a.out" 2>&1; rcV=$?
if grep -q 'COPY NAME IS' "$cpv/a.out"; then
    echo "copysubst: $(grep -o 'COPY NAME IS .*' "$cpv/a.out" | head -1) -- the COPY'd card did not substitute (#307)"; fail=1
elif grep -q 'BODY NAME IS' "$cpv/a.out"; then
    echo "copysubst: $(grep -o 'BODY NAME IS .*' "$cpv/a.out" | head -1) -- the body call itself is wrong"; fail=1
elif [ $rcV != 0 ]; then
    echo "copysubst: rc $rcV, expected 0"; cat "$cpv/a.out"; fail=1
else
    echo "copysubst: OK (a COPY'd card substitutes, and its AIF reads the expansion's variables)"
fi
rm -rf "$cpv"

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
# P and Z left this list when step 2 implemented them, E and L when step 3 did,
# and S when #108 did.  Q remains, and stays until the pseudo-register feature
# lands with it (#76).
for t in "Q(T)"; do
    printf 'T        CSECT\nD1       DC    %s\n         END\n' "$t" > /tmp/_d53.s
    ./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
    if [ $? -ne 8 ]; then echo "dc_types: FAIL (DC $t did not give RC 8)"; dcfail=1
    elif ! grep -q "not implemented by as370" /tmp/_d53.out; then
        echo "dc_types: FAIL (DC $t flagged, but not as unimplemented)"; dcfail=1; fi
done
# ...and the other direction, which is what #108 actually changed: S must no
# longer be reported at all.  Without this the loop above could be emptied by
# accident and nothing would notice.
printf 'T        CSECT\n         USING T,12\nD1       DC    S(T)\n         END\n' > /tmp/_d53.s
./as370 /tmp/_d53.s -o /tmp/_d53.obj >/tmp/_d53.out 2>&1
if [ $? -ne 0 ] || grep -q "not implemented by as370" /tmp/_d53.out; then
    echo "dc_types: FAIL (DC S is implemented now; it must assemble silently)"; dcfail=1; fi
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
[ $dcfail = 0 ] && echo "dc_types: OK (Q + CXD loud as unimplemented, S no longer; W/G as ERR198; implemented types unmoved)"
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

# START and ISEQ (cc370#127, #128).  Both were "undefined operation code" until
# now, which is why they showed up in a survey of MVS system source as MISSING
# MACROS: an unknown mnemonic looks the same either way.  START alone is the
# first cause of failure in 51 modules, ISEQ in 25.
#
# Every expectation below is IFOX00's own answer, measured on MVS/CE and not
# derived from the manual:
#
#   START 0    SD 0001 000000 ...     byte for byte the CSECT entry
#   START      SD 0001 000000 ...     the same
#   START 256  SD 0001 000100 ...     operand DECIMAL, and the ESD carries it
#   START 5    SD 0001 000008 ...     ROUNDED UP to a doubleword -- 256 is
#                                     already aligned and hides this; 5 shows it
#
# ISEQ emits nothing and does not advance the location counter, and an
# out-of-sequence statement is still assembled (IFO025 is a diagnostic, not a
# rejection).  So the assertion is that the object is IDENTICAL to the same
# source without it -- what is not yet reproduced is IFO025 itself.
startfail=0
for spec in "0:000000" ":000000" "256:000100" "5:000008"; do
    val=${spec%%:*}; want=${spec##*:}
    { echo "TESTX    START $val"; echo '         BR    14'; echo "FIELD    DC    F'1'"
      echo '         END'; } > /tmp/_st.s
    if ! ./as370 /tmp/_st.s -o /tmp/_st.obj >/dev/null 2>&1; then
        echo "start: ASSEMBLE FAILED for 'START $val'"; startfail=1; continue
    fi
    got=$(python3 -c "
import sys
d = open('/tmp/_st.obj','rb').read()
for o in range(0, len(d)-79, 80):
    c = d[o:o+80]
    if c[:4] == bytes((0x02,0xC5,0xE2,0xC4)):
        print('%06x' % int.from_bytes(c[16+9:16+12],'big')); break
")
    if [ "$got" != "$want" ]; then
        echo "start: FAIL 'START $val' -> SD ADDR $got, IFOX00 says $want"; startfail=1
    fi
done
{ echo 'SEQT     CSECT'; echo '         ISEQ  73,80'; echo '         BR    14'
  echo '         ISEQ'; echo '         END'; } > /tmp/_iq.s
{ echo 'SEQT     CSECT'; echo '         BR    14'; echo '         END'; } > /tmp/_nq.s
if ! ./as370 /tmp/_iq.s -o /tmp/_iq.obj >/dev/null 2>&1; then
    echo "iseq: ASSEMBLE FAILED"; startfail=1
elif ./as370 /tmp/_nq.s -o /tmp/_nq.obj >/dev/null 2>&1 && ! cmp -s /tmp/_iq.obj /tmp/_nq.obj; then
    echo "iseq: FAIL (ISEQ changed the object; it must emit nothing)"; startfail=1
fi
rm -f /tmp/_st.s /tmp/_st.obj /tmp/_iq.s /tmp/_iq.obj /tmp/_nq.s /tmp/_nq.obj
[ $startfail = 0 ] && echo "start/iseq: OK (four START forms match IFOX00's ESD; ISEQ is object-neutral)"
fail=$((fail + startfail))

# DC/DS type S (cc370#108).  A halfword carrying 4 bits of base register and 12
# of displacement.  Every byte below is IFOX00's own, one CSECT under
# USING TESTS,12, submitted to MVS/CE and read from SYSPRINT:
#
#   SA  DC  S(0)          0000    absolute -> displacement, base 0
#   SB  DC  S(4(3))       3004    explicit base 3, displacement 4
#   SC  DC  S(TARGET)     C010    base 12 from the USING
#   SD  DS  S             --      two bytes reserved, NO object code
#   SE  DC  2S(0,TARGET)  0000C0100000C010
#   TARGET DC F'7'        00000007        section length 000014
#
# S(0) is the row worth having.  Resolving an ABSOLUTE expression through the
# active USING gives C000, which is what a reasonable implementation does and
# what this one did until the oracle said otherwise -- and S(0) is the common
# null S-con, so it would have been wrong everywhere at once.
{ echo 'TESTS    CSECT'; echo '         USING TESTS,12'
  echo 'SA       DC    S(0)'; echo 'SB       DC    S(4(3))'
  echo 'SC       DC    S(TARGET)'; echo 'SD       DS    S'
  echo 'SE       DC    2S(0,TARGET)'; echo "TARGET   DC    F${q}7${q}"
  echo '         END'; } > /tmp/_s108.s
sfail=0
if ! ./as370 /tmp/_s108.s -o /tmp/_s108.obj >/dev/null 2>&1; then
    echo "stype: ASSEMBLE FAILED"; sfail=1
else
    # Address-keyed, not concatenated: DS S reserves two bytes and emits NONE,
    # so the text arrives as TWO records with a hole at 0x0006.  That hole is
    # itself the assertion -- a DS that emitted zeros would join the records and
    # still look plausible.
    got=$(python3 -c "
d = open('/tmp/_s108.obj','rb').read()
recs = []
esd = ''
for o in range(0, len(d)-79, 80):
    c = d[o:o+80]
    if c[:4] == bytes((0x02,0xE3,0xE7,0xE3)):
        n = (c[10] << 8) | c[11]
        recs.append('%06x:%s' % (int.from_bytes(c[5:8],'big'), c[16:16+n].hex()))
    if c[:4] == bytes((0x02,0xC5,0xE2,0xC4)):
        esd = '%06x' % int.from_bytes(c[16+13:16+16],'big')
print(' '.join(recs) + ' ' + esd)
")
    want="000000:00003004c010 000008:0000c0100000c01000000007 000014"
    if [ "$got" != "$want" ]; then
        echo "stype: FAIL"
        echo "       as370  $got"
        echo "       IFOX00 $want"
        sfail=1
    fi
fi
# ...and without addressability.  IFOX00, measured: the halfword is 0000 -- not
# the unresolved displacement -- and it raises IFO209 with the SAME wording it
# uses for an instruction operand, because it is the same situation.  as370 gave
# 0008 and a message of its own until the oracle said otherwise; two texts for
# one condition read as two defects.
{ echo 'NOADDR   CSECT'; echo 'SA       DC    S(TARGET)'; echo '         L     1,TARGET'
  echo "TARGET   DC    F${q}7${q}"; echo '         END'; } > /tmp/_s209.s
./as370 /tmp/_s209.s -o /tmp/_s209.obj >/tmp/_s209.out 2>&1
nmsg=$(grep -c "no active USING covers the operand" /tmp/_s209.out)
if [ "$nmsg" -ne 2 ]; then
    echo "stype: FAIL (IFO209 wording differs between the DC and the instruction: $nmsg of 2)"; sfail=1
elif ! python3 -c "
import sys
d = open('/tmp/_s209.obj','rb').read()
for o in range(0, len(d)-79, 80):
    c = d[o:o+80]
    if c[:4] == bytes((0x02,0xE3,0xE7,0xE3)) and int.from_bytes(c[5:8],'big') == 0:
        sys.exit(0 if c[16:18] == b'\x00\x00' else 1)
sys.exit(1)
"; then
    echo "stype: FAIL (an unaddressable S-con must assemble as 0000)"; sfail=1
fi
rm -f /tmp/_s209.s /tmp/_s209.obj /tmp/_s209.out
rm -f /tmp/_s108.s /tmp/_s108.obj
[ $sfail = 0 ] && echo "stype: OK (five S-type forms, the section length, and IFO209 match IFOX00)"
fail=$((fail + sfail))

# &SYSECT (cc370#132).  Unimplemented until now, and it expanded to NOTHING --
# the silent form: a macro line reading ((*-&SYSECT)/40) became ((*-)/40), and
# the duplication-factor check then reported IFO217, which is the consequence and
# not the cause.  61 macros in the mirrors use it, and 597 of 1,256 failing
# modules call one directly.
#
# Three rules, all measured on IFOX00 (MVS/CE), and the second is the one a
# reasonable implementation gets wrong:
#
#   1. the section in effect WHERE THE MACRO WAS CALLED; a DSECT counts
#   2. it does NOT follow a section change made INSIDE the expansion -- a macro
#      that opens INNER CSECT in its own body still yields the calling section
#      on the line after
#   3. in open code it is undefined (IFO006), not empty -- left to #97
#
# Rule 2 is why the value is frozen per invocation instead of looked up when the
# reference is resolved.  Looking it up is the obvious implementation, and it is
# wrong the same way resolving an absolute S-con through USING was in #108.
{ echo '         MACRO'; echo '         SHOWSECT'
  echo "         DC    C${q}&SYSECT${q}"
  echo 'INNER    CSECT'
  echo "         DC    C${q}&SYSECT${q}"
  echo '         MEND'
  echo 'FOURTH   CSECT'; echo '         SHOWSECT'; echo '         END'; } > /tmp/_se.s
{ echo '         MACRO'; echo '         SHOWSECT'
  echo "         DC    C${q}&SYSECT${q}"; echo '         MEND'
  echo 'THIRD    DSECT'; echo '         SHOWSECT'; echo '         END'; } > /tmp/_sd.s
sefail=0
if ! ./as370 /tmp/_se.s -o /tmp/_se.obj >/dev/null 2>&1; then
    echo "sysect: ASSEMBLE FAILED"; sefail=1
else
    # C'FOURTH' is C6D6E4D9E3C8, and it must appear TWICE in the TEXT -- the
    # second time AFTER the macro's own INNER CSECT.  Once would mean rule 2 is
    # not held.  Counted in the TXT records only: the name also stands in the
    # ESD as the section's own, which an object-wide count picks up as a third.
    n=$(python3 -c "
d = open('/tmp/_se.obj','rb').read()
t = b''
for o in range(0, len(d)-79, 80):
    c = d[o:o+80]
    if c[:4] == bytes((0x02,0xE3,0xE7,0xE3)):
        t += c[16:16+((c[10]<<8)|c[11])]
print(t.hex().count('c6d6e4d9e3c8'))
")
    if [ "$n" -ne 2 ]; then
        echo "sysect: FAIL (&SYSECT yielded the calling section $n time(s), expected 2)"; sefail=1
    fi
fi
# A DSECT generates no text, so the value is checked in the LISTING instead of
# the object -- asserting only that it assembles would pass on an empty &SYSECT,
# which is exactly the silent failure this closes.
./as370 -a /tmp/_sd.s -o /tmp/_sd.obj > /tmp/_sd.lst 2>&1
if ! grep -q "DC    C'THIRD'" /tmp/_sd.lst; then
    echo "sysect: FAIL (&SYSECT in a DSECT did not expand to THIRD)"
    grep -m1 "DC    C'" /tmp/_sd.lst || true
    sefail=1
fi
rm -f /tmp/_se.s /tmp/_se.obj /tmp/_sd.s /tmp/_sd.obj
[ $sefail = 0 ] && echo "sysect: OK (frozen at the call; a section opened inside the expansion does not move it)"
fail=$((fail + sefail))

# Cross-section duplication factor (cc370#133).  The counterpart to the case
# above, and the reason both are tested together: xrl_ counts how MANY
# relocatable terms an expression has, not which SECTIONS they came from, so
#
#     (*-TESTP)/40        one section, absolute      -> IFOX assembles it
#     (OTHER-TESTQ)       two sections, not absolute -> IFOX gives IFO206, RC 8
#
# both net to zero and were indistinguishable.  as370 read the second as the
# absolute value 0, which is a LEGAL and silent duplication factor: the statement
# vanished and the assembly ended RC 0.
#
# It moves no byte, which is why it survived this long.  The damage is a wrong
# CATEGORY -- a module IFOX rejects went into the recovery comparison as
# "assembled", differed, and the difference was charged to the source.
#
# The positive half is asserted in the same case, because the obvious fix breaks
# it: '*' is relocatable and belongs to the CURRENT section, and forgetting to
# tally it that way makes (*-TESTP) look cross-section and rejects valid code.
# That happened here on the first attempt.
dupfail=0
{ echo 'TESTQ    CSECT'; echo 'OTHER    CSECT'
  echo "BAD      DC    (OTHER-TESTQ)C${q}X${q}"; echo '         END'; } > /tmp/_x133.s
./as370 /tmp/_x133.s -o /tmp/_x133.obj >/tmp/_x133.out 2>&1
if [ $? -ne 8 ]; then
    echo "dupsect: FAIL (a cross-section duplication factor must give RC 8, IFOX00 IFO206)"; dupfail=1
elif ! grep -q "not from one section" /tmp/_x133.out; then
    echo "dupsect: FAIL (flagged, but not as IFO206): $(grep -m1 ERROR /tmp/_x133.out)"; dupfail=1
fi
{ echo 'TESTP    CSECT'; echo '         USING TESTP,12'; echo '         DS    (80)X'
  echo 'PATCH    DC    ((*-TESTP)/40)S(*)'; echo "AFTER    DC    X${q}FF${q}"
  echo "DUP2     DC    ((AFTER-TESTP)/8)C${q}AB${q}"; echo '         END'; } > /tmp/_y133.s
if ! ./as370 /tmp/_y133.s -o /tmp/_y133.obj >/dev/null 2>&1; then
    echo "dupsect: FAIL (a same-section factor is absolute and must still assemble)"; dupfail=1
else
    # ...and it must produce IFOX00's bytes, not merely assemble: c050c052 is the
    # pair of S-cons, and '*' advancing per copy is what makes them differ.
    got=$(python3 -c "
d = open('/tmp/_y133.obj','rb').read()
t = b''
for o in range(0, len(d)-79, 80):
    c = d[o:o+80]
    if c[:4] == bytes((0x02,0xE3,0xE7,0xE3)):
        t += c[16:16+((c[10]<<8)|c[11])]
print(t.hex()[:12])
")
    if [ "$got" != "c050c052ff" ] && [ "${got#c050c052}" = "$got" ]; then
        echo "dupsect: FAIL (same-section factor assembled but the bytes moved: $got)"; dupfail=1
    fi
fi
rm -f /tmp/_x133.s /tmp/_x133.obj /tmp/_x133.out /tmp/_y133.s /tmp/_y133.obj
[ $dupfail = 0 ] && echo "dupsect: OK (cross-section rejected IFO206; same-section still absolute and unmoved)"
fail=$((fail + dupfail))

# Compare two decks up to (not including) the END card, which differs only in
# the optional translator IDR. Written as a function over temp files because
# run.sh runs under sh: no process substitution.
deck_eq() {
    de_ref_sz=$(wc -c < "$2"); de_my_sz=$(wc -c < "$1")
    [ "$de_ref_sz" = "$de_my_sz" ] || return 1
    de_n=$(( (de_ref_sz / 80 - 1) * 80 ))
    head -c "$de_n" "$1" > /tmp/_de_a.$$; head -c "$de_n" "$2" > /tmp/_de_b.$$
    cmp -s /tmp/_de_a.$$ /tmp/_de_b.$$; de_rc=$?
    rm -f /tmp/_de_a.$$ /tmp/_de_b.$$
    return $de_rc
}

# sysparm_substr is the issue's own named case, rebuilt as our own code:
# '&SYSPARM'(1,4) on an empty &SYSPARM, in open code AND in a macro body, the
# way the real IEDHJN writes it. IFOX00 raises IFO117 in both and counts TWO
# flagged statements over THREE messages -- the open-code SETC, and the macro
# CALL line carrying both of the body's. That is why the diagnostic lives in
# eval_setc rather than in the open-code path: 420 MVSBLD modules call such a
# macro, and as370 called every one of them clean.
#
# setc_substr and var_opcode are byte-identity fixtures too, but they return 8
# BY DESIGN and so cannot ride in the loop above, which treats RC>=8 as a failed
# assembly. Both decks are IFOX00's, captured with --deck-on-error.
#
# setc_substr pins all four substring boundaries in one assembly, and the
# STATEMENT NUMBERS matter as much as the bytes: IFOX00 flags 25, 27, 28 and 29.
# var_opcode pins the operation-field rule -- '&O' holding 'DC' is substituted
# and assembles, '&P' holding a MACRO NAME is substituted and then REJECTED,
# because macro calls are already resolved when substitution runs.
# kwundef is the #162 oracle and returns 8 by design: a keyword the prototype
# does not declare is IFO092 KEYWORD PARAMETER <name> UNDEFINED IN MACRO
# DEFINITION, severity 8, one message per keyword -- and the expansion goes ahead.
# Going ahead is the point, not a leniency: the 118 modules this reaches already
# have decks byte-identical to IFOX00's, because MODID emits nothing for an
# operand it does not know and neither do we. Refusing the call would turn 115
# identities into differences; the divergence is the RETURN CODE, which a byte
# comparison cannot see.
# C3 carries TWO undeclared keywords in ONE statement: two messages, one flagged
# statement. That separates the message count from the statement count, and
# without it the counting rule is not tested at all.
rc8fail=0
for s8 in setc_substr:4:8 var_opcode:1:8 sysparm_substr:2:8 kwundef:2:8; do
    f8=${s8%%:*}; rest8=${s8#*:}; nf8=${rest8%%:*}; rc8=${rest8##*:}
    ./as370 "tests/$f8.s" -o "/tmp/_$f8$$.obj" >/dev/null 2>"/tmp/_$f8$$.err"; got8=$?
    if [ $got8 != $rc8 ]; then
        echo "$f8: FAIL (expected RC $rc8, got $got8)"; rc8fail=1
    elif ! deck_eq "/tmp/_$f8$$.obj" "tests/ref/$f8.obj"; then
        echo "$f8: FAIL (deck differs from IFOX00)"; rc8fail=1
    elif [ "$nf8" != 1 ] && ! grep -q "$nf8 Statements Flagged" "/tmp/_$f8$$.err"; then
        echo "$f8: FAIL (expected IFOX's $nf8 flagged statements)"; rc8fail=1
    else
        echo "$f8: OK (== IFOX00, RC $rc8, $nf8 flagged)"
    fi
    rm -f "/tmp/_$f8$$.obj" "/tmp/_$f8$$.err"
done
fail=$((fail + rc8fail))

# #151 is CLOSED: a SETC value is held to IFOX00's 255 characters, not 95.
# This block used to assert the DIVERGENCE and was written to fail the day the
# defect was fixed -- "drop this test and compare the decks". It did exactly
# that when the macro-path buffers were raised, so the fixture has moved into
# the deck loop above and its oracle now stands as a plain byte-identity check.
# tests/ref/setc_len95.obj is unchanged; only what we assert about it is.

# --- issue #141: variable symbols are substituted in OPEN CODE ---
# --- issue #141: variable symbols are substituted in OPEN CODE ---------------
# The issue's own fixture. as370 emitted BA50C1BBBA50C2BB -- the variable NAMES
# as data -- at rc 0, where IFOX00 emits BABBBAC2C3C4BB and returns 8. Three
# things are asserted because the defect had three faces: the deck, the listing
# and the return code.
#
# The listing is the part that is easy to get half right. IFOX00 lists the
# conditional-assembly statements (ALOGIC is on by default) and prints a
# substituted model statement TWICE -- the source card with no location, then
# the generated card with the object code and the '+'. So the DC is statement 23
# and 24+, not statement 20.
#
# The statement NUMBER and the "in line N" number are different things and both
# are checked: as370 reports the input CARD (line_org), which for this fixture
# is 21 and happens to equal IFOX's statement number only because every card
# ahead of it is a listed statement.
sofail=0
./as370 tests/setc_open.s -o /tmp/_so$$.obj -a >/tmp/_so$$.lst 2>/tmp/_so$$.err; rcso=$?
nbe=$(( ($(wc -c < tests/ref/setc_open.obj) / 80 - 1) * 80 ))
if [ $rcso != 8 ]; then
    echo "setc_open: FAIL (expected RC 8 for IFO117, got $rcso)"; sofail=1
elif ! deck_eq /tmp/_so$$.obj tests/ref/setc_open.obj; then
    echo "setc_open: FAIL (deck differs from IFOX00 -- substitution or the substring)"; sofail=1
elif ! grep -q 'IFO117) in line 21' /tmp/_so$$.err; then
    echo "setc_open: FAIL (no IFO117 on the SETC card)"; sofail=1
elif ! grep -q '1 Statement Flagged /   8 was Highest Severity' /tmp/_so$$.err; then
    echo "setc_open: FAIL (not IFOX's 1 flagged statement at severity 8)"; sofail=1
elif ! grep -qE '^ +23 +DC +C.\[&A\]\[&B\]' /tmp/_so$$.lst; then
    echo "setc_open: FAIL (the model statement is not listed as statement 23)"; sofail=1
elif ! grep -qE '^000000 BABBBAC2C3C4BB +24\+' /tmp/_so$$.lst; then
    echo "setc_open: FAIL (no generated statement 24+ carrying the object code)"; sofail=1
elif ! grep -qE "^ +21 &A +SETC" /tmp/_so$$.lst; then
    echo "setc_open: FAIL (the SETC statement is not listed -- ALOGIC)"; sofail=1
else
    echo "setc_open: OK (deck == IFOX00, RC 8, IFO117, model 23 + generated 24+)"
fi
rm -f /tmp/_so$$.obj /tmp/_so$$.lst /tmp/_so$$.err

# The remarks field is NOT substituted, and a system variable pairs like any
# other substitution. Both measured in tests/listref/ifox-listing-remark_sub.txt:
# statement 24+ carries 'BEMERKUNG &X UND & ENDE' verbatim -- the reference to
# &X and the bare '&' both survive -- and &SYSDATE produces its own 26/27+ pair.
# Listing-only by construction: &SYSDATE would date-stamp a deck.
./as370 tests/remark_sub.s -o /dev/null -a >/tmp/_rs$$.lst 2>&1
if ! grep -qE '^000000 E9 +24\+' /tmp/_rs$$.lst; then
    echo "remark_sub: FAIL (no generated statement 24+ for the substituted DC)"; sofail=1
elif ! grep -q 'BEMERKUNG &X UND & ENDE' /tmp/_rs$$.lst; then
    echo "remark_sub: FAIL (the remarks field was substituted -- it must be verbatim)"; sofail=1
elif ! grep -qE '^ +26 C +DC +C.&SYSDATE' /tmp/_rs$$.lst; then
    echo "remark_sub: FAIL (&SYSDATE did not produce a model/generated pair)"; sofail=1
else
    echo "remark_sub: OK (remarks verbatim; &SYSDATE pairs)"
fi
rm -f /tmp/_rs$$.lst

# R2, and it is deliberately NOT IFOX00 parity. tests/setc_undef.s is #97's
# oracle: IFOX00 raises IFO006 and generates NO object code for the statement,
# and takes no cross-reference entry for its name. as370 leaves an unresolvable
# reference EXACTLY as written instead -- concatenation dot included -- so the
# card is byte-identical to what it was before substitution existed -- the X'4B'
# in the expected bytes IS that dot, kept. That keeps
# #141 from trading one class of wrong bytes for another while #97 is open.
./as370 tests/setc_undef.s -o /tmp/_su$$.obj >/dev/null 2>&1
got=$(python3 -c "
d=open('/tmp/_su$$.obj','rb').read(); t=b''
for o in range(0,len(d)-79,80):
    c=d[o:o+80]
    if c[:4]==bytes((0x02,0xE3,0xE7,0xE3)): t+=c[16:16+((c[10]<<8)|c[11])]
print(t.hex())
")
if [ "$got" != "c1e9c2c150e44bc2c5d5c4" ]; then
    echo "setc_undef: FAIL (expected AZB + A&U.B verbatim + END, got $got)"; sofail=1
else
    echo "setc_undef: OK (&X substituted, undefined &U left verbatim -- #97, not #141)"
fi
rm -f /tmp/_su$$.obj
fail=$((fail + sofail))

# '&&' folding, and where it belongs. Measured against IFOX00 three ways:
# tests/amp_fold.s (no variable symbol in the module at all -- DC folds anyway),
# tests/amp_subst.s (the generated line still carries '&&' and emits three
# bytes, so substitution passes the pair through and only DC folds) and
# tests/amp_selfdef.s (C'&&' is one byte in an EXPRESSION too, and a literal's
# length counts the pair as one).
#
# as370 used to do the exact opposite on both counts -- msub folded, the DC
# scanner did not -- so the two defects cancelled and 950 modules of deck
# byte-identity could never show it. amp_subst is in the byte-identity loop
# above and is what holds the pair together: repair either half alone and it
# fails.
#
# amp_fold and amp_selfdef were NOT byte-identical, and not because of '&&':
# L' of a C constant with no explicit length was 1 where IFOX00 gives the
# constant's length (#148). This test used to pin the difference to exactly
# those two bytes -- 104 and 99 -- and to FAIL once they matched, so the defect
# could not be fixed unnoticed. #148 is fixed, both bytes match, and the two
# fixtures have moved into the byte-identity loop above where they belong.
#
# len_attr.s went with them. It is the #148 oracle proper: eight symbols whose
# L' is read three different ways -- from an explicit length (CL7), from a
# type's fixed implied length (F, H, A), and from the nominal value (C, X, and
# a duplicated 3C'AB' whose L' is 2, the length of ONE constant, not the
# field's 6). The boundary is in the deck, so a repair that fixes only the
# first group cannot pass.

# msub's destination is bounded. Substitution EXPANDS, by a factor no call site
# can bound from its own input: a reference costs two characters to write and
# vref returns up to 95, so the worst case is 47.5x -- and all four call sites
# hand msub a 256- or 1024-byte automatic buffer. Ten cards of ordinary
# conditional assembly walked off eval_setc's sub[256], mexp_macro's ex[1024]
# and render_model's sub[256], and as370 STILL EXITED 0. Only a sanitizer sees
# it, so this test builds one; where the host compiler has none it skips rather
# than pretending to have checked.
asanfail=0
asanbin=/tmp/_as370_asan$$
if ${CC:-cc} -fsanitize=address -O0 -g -Iinclude -I../common/include \
        -o $asanbin src/as370.c ../common/src/mvs370.c ../common/src/obj370.c \
        >/dev/null 2>&1; then
    ASAN_OPTIONS=detect_leaks=0 $asanbin tests/msub_overflow.s -o /tmp/_msub$$.obj \
        >/tmp/_msub$$.out 2>&1
    rcm=$?
    if grep -q "AddressSanitizer" /tmp/_msub$$.out; then
        echo "msub_overflow: FAIL (sanitizer report -- msub wrote past its destination)"
        grep -m2 -E "ERROR: AddressSanitizer|in msub " /tmp/_msub$$.out
        asanfail=1
    elif [ $rcm -ge 128 ]; then
        echo "msub_overflow: FAIL (as370 died with signal $((rcm - 128)))"; asanfail=1
    else
        echo "msub_overflow: OK (bounded -- no sanitizer report on a 47.5x expansion)"
    fi
    rm -rf $asanbin $asanbin.dSYM /tmp/_msub$$.obj /tmp/_msub$$.out
else
    echo "msub_overflow: SKIPPED (host compiler has no -fsanitize=address)"
fi
fail=$((fail + asanfail))

[ $fail = 0 ] && echo "ALL SAMPLES BYTE-IDENTICAL TO IFOX00" || echo "FAILURES"
exit $fail
