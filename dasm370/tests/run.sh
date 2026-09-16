#!/bin/sh
# dasm370 regression.
#
# TWO HALVES, AND NEITHER SUBSTITUTES FOR THE OTHER.
#
#   The ROUND TRIP -- dasm370 -> as370, deck against deck -- proves the output
#   reassembles to the bytes it came from. It cannot see which of two spellings
#   of the same encoding was printed, and that is measured rather than assumed:
#   a mutant of opc_table.h with BE and BZ's `dec' swapped prints `BZ' for X'47'
#   mask 8 and STILL ROUND-TRIPS IDENTICALLY. A suite that only ran the round
#   trip would have been green on a decoder that names the wrong instruction.
#
#   The MNEMONIC assertions below are what that mutant fails. They are not
#   decoration: `dec' exists because several entries claim one encoding, and
#   which one a reader is handed is the whole product of the decode.
#
# The fixture is a SOURCE, tests/formats.s, and not a hand-built deck: as370 is
# the encoder, so the bytes under test are the ones the assembler really emits
# and there is one reader on each side of the comparison.
cd "$(dirname "$0")/.." || exit 2
D=./dasm370
A=../as370/as370
T="${TMPDIR:-/tmp}/dasm370-tests.$$"
mkdir -p "$T" || exit 2
trap 'rm -rf "$T"' EXIT

fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails + 1)); }

[ -x "$A" ] || { echo "dasm370: as370 not built at $A"; exit 2; }

"$A" tests/formats.s -o "$T/a.obj" > "$T/asm.out" 2>&1
if [ $? -ge 8 ]; then echo "FAIL: the fixture does not assemble"; cat "$T/asm.out"; exit 1; fi

# ---- the round trip -------------------------------------------------------
"$D" "$T/a.obj" -o "$T/b.s" 2>"$T/d.err"
if [ $? != 0 ]; then fail "dasm370 exited non-zero"; cat "$T/d.err"; fi
"$A" "$T/b.s" -o "$T/b.obj" > "$T/asm2.out" 2>&1
rc=$?
n=$(( ($(wc -c < "$T/a.obj") / 80 - 1) * 80 ))
# Every card before the END, which legitimately differs in its optional IDR.
head -c $n "$T/a.obj" > "$T/a.cut"
head -c $n "$T/b.obj" > "$T/b.cut"
if [ $rc -ge 8 ]; then
    fail "the disassembly does not assemble (rc $rc)"
    head -5 "$T/asm2.out"
elif cmp -s "$T/a.cut" "$T/b.cut"; then
    pass "round trip: the deck reassembles byte-identically (ESD, TXT and RLD)"
else
    fail "round trip: the deck differs"
    cmp "$T/a.cut" "$T/b.cut" | head -3
fi

# ---- what the round trip cannot see ---------------------------------------
# Every line here fails on a `dec' mutant that round-trips perfectly.
"$D" --format free "$T/a.obj" -o "$T/free.s" 2>/dev/null
want() {                       # want <regex> <what it proves>
    if grep -qE "$1" "$T/free.s"; then pass "$2"
    else fail "$2"; fi
}
deny() {
    if grep -qE "$1" "$T/free.s"; then fail "$2"; else pass "$2"; fi
}

want '^ +BE +' "X'47' mask 8 decodes as BE"
deny '^ +BZ +' "and not as BZ -- the measured spelling, 34446 against 32011"
want '^ +BNE +' "mask 7 decodes as BNE"
want '^ +BNH +' "mask 13 decodes as BNH"
want '^ +BC +3,' "a mask no pseudo names falls back to the generic BC"
want '^ +BR +14' "X'07' mask 15 decodes as BR"
want '^ +BER +14' "X'07' mask 8 decodes as BER"
want '^ +BCR +5,14' "and BCR is the fallback there too"

# The three SS shapes. SRP is the one that punishes a guess: its length is in
# the high nibble and the rounding digit in the low one, so a single-length
# reading swaps them (cc370#64, in the other direction).
want '^ +MVC +0\(8,1\),0\(2\)' "SS one length"
want '^ +AP +0\(4,1\),0\(3,2\)' "SS two lengths"
want '^ +SRP +0\(8,1\),2\(0\),5' "SRP: one length, and the rounding digit as its own operand"

# One-byte S opcodes are spelled <op>00 in the table and are not the two-byte
# X'B2xx' group; nothing in the bytes distinguishes them (#374's `opw').
want '^ +LPSW +0\(1\)' "a one-byte S opcode written as <op>00"
want '^ +STIDP +0\(1\)' "a real two-byte S opcode"
# In free format a line is `<op> <remark>', and the remark is the address. So
# `PTLB' followed by nothing but six hex digits IS the no-operand assertion.
want '^ +PTLB +[0-9A-F]{6} *$' "F_S0 has no operand at all"
want '^ +IPK +[0-9A-F]{6} *$' "the other F_S0"

# The RLD is the one place an object deck has ground truth.
want '^ +DC +A\(ENTRYPT\)' "an A-con into this section names the ENTRY it points at"
want '^ +DC +V\(EXTNAME\)' "an external reference comes back as a V-con"
want '^ +ENTRY +ENTRYPT' "the LD entry is recovered -- invisible to any comparison of TEXT"
want '^ +EXTRN +EXTNAME' "and the ER with it"

# The END card's entry point is neither text nor a relocation, so NEITHER half
# of the acceptance sees it -- and it is what the linkage editor resolves a
# module's entry from. 23 of 30 modules lost it before this assertion existed.
want '^ +END +ENTRYPT' "the END card's entry point comes back, by the name it has"

# A hole is a hole. cmplmd370 tells `covered with zero' from `never defined',
# so a DS that came back as a DC would move a byte nobody wrote.
want '^HOLE|^ +DS +XL7' "an uncovered run comes back as DS, not as DC X'00..'"

# ---- card format ----------------------------------------------------------
"$D" --format card "$T/a.obj" -o "$T/card.s" 2>/dev/null
if [ "$(awk '{ if (length($0) != 80) n++ } END { print n+0 }' "$T/card.s")" = 0 ]; then
    pass "card format: every record is exactly 80 columns"
else
    fail "card format: a record is not 80 columns"
fi
if [ "$(awk '{ if (substr($0,72,1) != " ") n++ } END { print n+0 }' "$T/card.s")" = 0 ]; then
    pass "card format: column 72 is blank on every card"
else
    fail "card format: a card reaches column 72 -- it would eat the next one"
fi
if [ "$(awk '{ if (substr($0,73,8) !~ /^[0-9]{8}$/) n++ } END { print n+0 }' "$T/card.s")" = 0 ]; then
    pass "card format: columns 73-80 carry the sequence number"
else
    fail "card format: the sequence number is not in 73-80"
fi

# ---- refusals -------------------------------------------------------------
"$D" --csect NOSUCHCS "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 2 ] && pass "an unknown --csect exits 2, not 0" || fail "an unknown --csect exits 2, not 0"
"$D" --isa nonsense "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 16 ] && pass "an --isa value that is not one of the four is refused" \
             || fail "an --isa value that is not one of the four is refused"

[ $fails = 0 ] && echo "dasm370: all checks passed" || echo "dasm370: $fails FAILURE(S)"
exit $fails
