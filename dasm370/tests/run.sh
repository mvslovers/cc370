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
#
# THE HINTS BLOCK IS SCORED AGAINST MUTANTS, not against itself. Most of what
# --hints adds is a RULE rather than a behaviour -- "VERIFY reads the original
# bytes", "refuse, never skip", "write a symbol only where as370 would pick the
# register the bytes name" -- and a rule cannot be demonstrated by a fixture
# that passes. So each was mutated out of dasm370.c and the suite re-run:
#
#   sym_disp writes a symbol whatever register as370 would pick    2 fail
#       ... including the DECK comparison under the overlap, which is the
#       strong form: the symbol resolves to the same address and the
#       assembler re-encodes it against a different base register.
#   REPLACE applied BEFORE VERIFY                                  1 fail
#       ... and only the LITERAL verify catches it. The date-shaped one does
#       not: the patched bytes are a valid date too.
#   an unknown key is skipped instead of refused                   1 fail
#   the output file is opened before the hints are bound           4 fail
#   the fill uniformity check is dropped                           1 fail
#   two live bases on one register are allowed                     1 fail
#   the `scanning' guard is removed from emit()                   10 fail
#   the comment stripper cuts at the first `#' anywhere             1 fail
#       ... `#', `$' and `@' are ALPHABETIC in Assembler XF, so R#SAVE is an
#       ordinary label. This one was a real defect, found in review.
#
# Scored on 2026-09-16 with a rebuild guard on the binary's sha256. Without
# one, two mutants ran against the same build -- make's mtime granularity is a
# second and the harness rewrote the source faster than that -- and the second
# score was the first mutant's, reported against the second mutant's name.
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

# ---- hints (#382) ---------------------------------------------------------
# Every hint file is written here rather than committed, so the thing being
# asserted and the thing being read are one screen apart. The offsets are the
# fixture's own: 0xD0 the mm/dd/yy date, 0xD8 the Julian one, 0xDE a 24-byte
# uniform run, 0xF6 eight bytes that decode as four LRs and are not code.
H="$T/h"
hrun() {                       # hrun <file> <extra args...>; leaves rc in $hrc
    rm -f "$T/out.s"
    "$D" --format free --hints "$1" "$T/a.obj" -o "$T/out.s" >"$T/h.out" 2>&1
    hrc=$?
}
hwant() { if grep -qE "$1" "$T/out.s"; then pass "$2"; else fail "$2"; sed -n 1,3p "$T/h.out"; fi; }
hdeny() { if grep -qE "$1" "$T/out.s"; then fail "$2"; else pass "$2"; fi; }
# A refusal has to leave NO file behind, not merely a non-zero rc: a half
# written disassembly that assembles is the failure this whole tool is shaped
# against. So the output is opened last and every refuse() asserts both.
refuse() {                     # refuse <file> <what it proves>
    hrun "$1"
    if [ $hrc = 16 ] && [ ! -e "$T/out.s" ]; then pass "$2"
    else fail "$2 (rc $hrc, output file $([ -e "$T/out.s" ] && echo left || echo absent))"
         sed -n 1,2p "$T/h.out"; fi
}

cat > "$H.using" <<'EOF'
prefix = "P"
[[label]]
at   = 0xAC
name = "MVCTARG"
[[base]]
reg   = 12
value = 0x2
from  = 0x2
to    = 0xB2
EOF
hrun "$H.using"
[ $hrc = 0 ] && pass "a hint file with a [[base]] is accepted" || { fail "a hint file with a [[base]] is accepted"; cat "$T/h.out"; }
hwant '^ +USING +P000002,12' "the USING statement is emitted where the file says the base begins"
hwant '^ +DROP +12'          "and dropped where the file says it ends"
hwant '^P0000A4 +BR +14'     "a BC target under the base gets a label -- nothing else in the module names it"
hwant '^ +BE +P0000A4'       "and the branch names it instead of 162(0,12)"
hwant '^ +EX +0,MVCTARG'     "a [[label]] outranks the manufactured name"
hwant '^ +L +4,P000002\+X.E.\(1\)' "the index register survives symbolisation"
hdeny '^ +BE +162'           "no branch is left numeric under the base"

# The round trip, with the hints applied. This is the one that would catch a
# symbol resolving to an address the assembler puts somewhere else.
"$D" --hints "$H.using" "$T/a.obj" -o "$T/hc.s" 2>/dev/null
"$A" "$T/hc.s" -o "$T/hc.obj" > "$T/hc.out" 2>&1
if [ $? -ge 8 ]; then fail "the hinted disassembly does not assemble"; head -5 "$T/hc.out"
else
    head -c $n "$T/hc.obj" > "$T/hc.cut"
    cmp -s "$T/a.cut" "$T/hc.cut" \
        && pass "round trip with hints: the deck still reassembles byte-identically" \
        || { fail "round trip with hints: the deck differs"; cmp "$T/a.cut" "$T/hc.cut" | head -3; }
fi

# TWO bases over one target, and the bytes name the register as370 would NOT
# pick. R11 is a deliberate fiction -- nothing in the fixture loads it -- but
# as370's rule is smallest displacement, so it wins the targets around X'A4'
# and every base-12 operand there must come back NUMERIC. Drop the check in
# as370_base_for() and this still looks right and the deck stops matching.
cat > "$H.overlap" <<'EOF'
[[base]]
reg   = 12
value = 0x2
from = 0x2
to   = 0xB2
[[base]]
reg   = 11
value = 0x60
from  = 0x2
to    = 0xB2
EOF
hrun "$H.overlap"
hwant '^ +BE +162\(0,12\)' "a second base that as370 would prefer forces the numeric form back"
"$D" --hints "$H.overlap" "$T/a.obj" -o "$T/ov.s" 2>/dev/null
"$A" "$T/ov.s" -o "$T/ov.obj" > /dev/null 2>&1
head -c $n "$T/ov.obj" > "$T/ov.cut" 2>/dev/null
cmp -s "$T/a.cut" "$T/ov.cut" \
    && pass "and the deck is still byte-identical under the overlap" \
    || fail "and the deck is still byte-identical under the overlap"

# `to' may be omitted. The default is not a guess: one base register addresses
# 4096 bytes, so that is where it stops on its own -- clamped to the section.
# mvs38dasm's BASE statement documents the same default.
cat > "$H.noto" <<'EOF'
[[base]]
reg   = 12
value = 0x2
from  = 0x2
EOF
hrun "$H.noto"
[ $hrc = 0 ] && pass "a [[base]] without \`to' is accepted" || fail "a [[base]] without \`to' is accepted"
hwant '^ +BE +L0000A4' "and reaches from + 4096, clamped to the section, so the whole of it resolves"
hwant '^ +DROP +12'    "and the DROP still marks where the assertion stops"
hwant '^L0000A4 +BR'   "the default prefix is L, since this file sets none"

cat > "$H.dupreg" <<'EOF'
[[base]]
reg   = 12
value = 0x2
from  = 0x2
to    = 0x80
[[base]]
reg   = 12
value = 0x4
from  = 0x40
to    = 0xB2
EOF
refuse "$H.dupreg" "two live bases on one register are refused -- as370 holds one entry per register"

cat > "$H.nolife" <<'EOF'
[[base]]
reg   = 12
value = 0x2
from  = 0x40
to    = 0x40
EOF
refuse "$H.nolife" "a base whose range is empty is refused -- #112 has no form without a lifetime"

# A label inside an instruction re-cuts it, and that is right: something enters
# there, so the boundary we had was the wrong one.
cat > "$H.midins" <<'EOF'
[[label]]
at   = 0x6
name = "MIDDLE"
EOF
hrun "$H.midins"
hwant '^ +DC +X.4130.'  "a [[label]] inside an instruction turns it into DC"
hdeny '^ +LA +3,'       "and the instruction it split is gone"
hwant '^MIDDLE +DC'     "with the label on the second half"

# `#', `$' and `@' are ALPHABETIC to Assembler XF, so R#SAVE is an ordinary
# label and IBM's source is full of them. A comment stripper that cuts at the
# first `#' anywhere would take this file's name in half -- and --derive-hints
# will write exactly such names out of real source.
cat > "$H.hash" <<'EOF'
[[label]]
at   = 0x100
name = "R#SAVE"     # and a real comment, after the value
EOF
hrun "$H.hash"
hwant '^R#SAVE +DC' "a # inside a quoted name is part of the name, not the start of a comment"

cat > "$H.data" <<'EOF'
[[data]]
at  = 0xF6
len = 8
EOF
hrun "$H.data"
hwant "^ +DC +X'1822188218831884'" "[[data]] stops a run decoding as instructions"
hdeny '^ +LR +8,4' "and the LR it was decoding as is gone"

cat > "$H.fill" <<'EOF'
[[fill]]
at  = 0xDE
len = 24
EOF
hrun "$H.fill"
hwant "^ +DC +24X'00'" "[[fill]] writes a duplication factor instead of two cards of hex"

cat > "$H.fillbad" <<'EOF'
[[fill]]
at  = 0xD0
len = 8
EOF
refuse "$H.fillbad" "a [[fill]] over a run that is not uniform is refused"

cat > "$H.fillhole" <<'EOF'
[[fill]]
at  = 0xC5
len = 4
EOF
refuse "$H.fillhole" "a [[fill]] over bytes no TXT defined is refused -- that run is a DS"

# VERIFY and REPLACE. The order is the argument: VERIFY reads the ORIGINAL
# bytes, which is the only reason REPLACE is safe. Patch the two halves in the
# other order and the verify below passes on bytes it did not assert.
cat > "$H.rep" <<'EOF'
[[verify]]
at   = 0xD0
date = "mdy"
[[replace]]
at    = 0xD0
bytes = "F0F161F0F161F7F0"
EOF
hrun "$H.rep"
[ $hrc = 0 ] && pass "a REPLACE under a covering VERIFY is applied" || fail "a REPLACE under a covering VERIFY is applied"
hwant 'F0F161F0F161F7F0' "and the patched bytes are what comes out"

# The ORDER, pinned by a literal VERIFY rather than a date one. A date-shaped
# verify cannot see the swap -- the patched bytes are a valid date too -- so it
# would pass on a binary that patched first and asserted afterwards, which is
# the one thing the pair exists to prevent.
cat > "$H.order" <<'EOF'
[[verify]]
at    = 0xD0
bytes = "F0F961F0F761F2F6"
[[replace]]
at    = 0xD0
bytes = "F0F161F0F161F7F0"
EOF
hrun "$H.order"
[ $hrc = 0 ] && pass "VERIFY reads the ORIGINAL bytes: assert-then-patch, not patch-then-assert" \
             || { fail "VERIFY reads the ORIGINAL bytes: assert-then-patch, not patch-then-assert"; sed -n 1,2p "$T/h.out"; }

cat > "$H.repbare" <<'EOF'
[[replace]]
at    = 0xD0
bytes = "F0F161F0F161F7F0"
EOF
refuse "$H.repbare" "a REPLACE no VERIFY covers is refused -- an unasserted patch is the unsafe one"

cat > "$H.verbad" <<'EOF'
[[verify]]
at    = 0xD0
bytes = "0102030405060708"
EOF
refuse "$H.verbad" "a VERIFY mismatch refuses, and writes nothing"
grep -q "the module holds F0F961F0F761F2F6" "$T/h.out" \
    && pass "and the refusal prints what the module actually holds" \
    || fail "and the refusal prints what the module actually holds"

# Both date shapes, and each rejecting the other's. One shape alone is noisy
# over 430 decks (#112), which is why there are two.
cat > "$H.dmdy" <<'EOF'
[[verify]]
at   = 0xD0
date = "mdy"
EOF
hrun "$H.dmdy"; [ $hrc = 0 ] && pass "date = \"mdy\" matches 09/07/26" || fail "date = \"mdy\" matches 09/07/26"
cat > "$H.djul" <<'EOF'
[[verify]]
at   = 0xD8
date = "julian"
EOF
hrun "$H.djul"; [ $hrc = 0 ] && pass "date = \"julian\" matches 26.250" || fail "date = \"julian\" matches 26.250"
cat > "$H.dcross" <<'EOF'
[[verify]]
at   = 0xD8
date = "mdy"
EOF
refuse "$H.dcross" "and mdy refuses the Julian one"
cat > "$H.dcross2" <<'EOF'
[[verify]]
at   = 0xD0
date = "julian"
EOF
refuse "$H.dcross2" "and julian refuses the mm/dd/yy one"

# The grammar refuses; it does not skip. A hint silently ignored is a file that
# looks applied and is not, which is the failure mode this format exists under.
printf 'prefix = "P"\nnosuchkey = 3\n'        > "$H.badkey"
refuse "$H.badkey" "an unknown key is refused, not ignored"
printf '[[nosuchtable]]\nat = 0\n'            > "$H.badtab"
refuse "$H.badtab" "an unknown table is refused"
printf '[label]\nat = 0\n'                    > "$H.single"
refuse "$H.single" "a single-bracket table is refused -- there is one way to write one"
printf 'base = 0x10\n'                        > "$H.base"
refuse "$H.base" "\`base' at the root says it is a table, rather than doing nothing"
printf '[[using]]\nreg = 12\n'                > "$H.using2"
refuse "$H.using2" "[[using]] says it is not implemented -- a USING points at a DSECT, [[base]] at this section"
printf '[[label]]\nat = 0x10\nat = 0x20\n'    > "$H.dup"
refuse "$H.dup" "a key given twice is refused"
printf '[[label]]\nat = 0x10\n'               > "$H.noname"
refuse "$H.noname" "a missing required key is refused"
printf '[[label]]\nat = 0x10\nname = 3\n'     > "$H.wrongkind"
refuse "$H.wrongkind" "a value of the wrong kind is refused"
printf '[[label]]\nat = 0x9999\nname = "X"\n' > "$H.outside"
refuse "$H.outside" "an offset outside the section is refused, not clamped"
printf '[[label]]\n[[label]]\nat = 0\nname = "X"\n' > "$H.empty"
refuse "$H.empty" "an EMPTY table is refused too -- skipping it is still skipping"
printf 'nonsense\n'                           > "$H.junk"
refuse "$H.junk" "a line that is not a comment, a header or key = value is refused"
printf '[[dsect]]\nname = "TCB"\n'            > "$H.dsect"
refuse "$H.dsect" "[[dsect]] says it is not implemented rather than doing nothing"
printf 'prefix = "TOOLONG"\n'                 > "$H.prefix"
refuse "$H.prefix" "a prefix longer than two characters is refused -- eight is all a symbol has"

rm -f "$T/out.s"
"$D" --hints "$T/does-not-exist" "$T/a.obj" -o "$T/out.s" >/dev/null 2>&1
[ $? = 16 ] && [ ! -e "$T/out.s" ] && pass "a hint file that cannot be opened is refused" \
                                   || fail "a hint file that cannot be opened is refused"

# ---- --derive-hints (#382, PR B) ------------------------------------------
# A TRANSLATOR, not an analysis: run as370, read --sym (#373) and --usings
# (#393), write a hint file. That is only possible because those two exports
# exist; before them the only route was scraping the printed listing, which is
# what mvs38dasm does for DSECT labels and which cannot answer the USING
# question at all.
#
# ON THE PRE-CHANGE BINARY (63a988d): `invalid option '--derive-hints'', rc 16.
# An additive option cannot score against a binary that rejects it, so the
# assertions below are what carry this -- plus the two acceptances from #382
# that CANNOT be faked: the round trip, and the wrong -I pair.
DH="$T/dh"
"$D" --derive-hints tests/derive.s --as370 "$A" -o "$DH.toml" 2>"$T/dh.err"
if [ $? = 0 ] && [ -s "$DH.toml" ]; then pass "--derive-hints writes a hint file"
else fail "--derive-hints writes a hint file"; cat "$T/dh.err"; fi
dwant() { if grep -qE "$1" "$DH.toml"; then pass "$2"; else fail "$2"; fi; }
dwant '^name = "LOOPTOP"'   "a label the source named comes back"
dwant '^at   = 0x6'         "at the offset as370 gave it"
dwant '^reg   = 12'         "the base register, with a lifetime"
dwant '^from  = 0x2'        "from where it was established"
dwant 'reason=dsect-domain' "a DSECT domain is a COMMENT, not a [[base]] -- [[using]] is refused"
dwant '^\[\[verify\]\]'     "anchors are written"
dwant '^#   -I ' "the -I list is IN the file, so a wrong macro library announces itself"

# Deterministic: two runs of the same inputs must be byte-identical, or the
# round-trip acceptance below cannot mean anything.
"$D" --derive-hints tests/derive.s --as370 "$A" -o "$DH.2" 2>/dev/null
cmp -s "$DH.toml" "$DH.2" && pass "two derive runs of one source are byte-identical" \
                          || fail "two derive runs of one source are byte-identical"

# #382's first acceptance, in its strongest available form: derive from x.s,
# apply to OUR OWN deck of x.s, and the disassembly must both carry the source's
# names AND reassemble to the bytes it came from.
"$A" tests/derive.s -o "$T/dv.obj" >/dev/null 2>&1
"$D" --format free --hints "$DH.toml" "$T/dv.obj" -o "$T/dv.s" 2>/dev/null
if grep -qE '^LOOPTOP +L +2,COUNTER' "$T/dv.s" && grep -qE '^ +BNE +LOOPTOP' "$T/dv.s"; then
    pass "applied to its own module the disassembly reads in the source's own names"
else
    fail "applied to its own module the disassembly reads in the source's own names"
    sed -n 1,12p "$T/dv.s"
fi
"$D" --hints "$DH.toml" "$T/dv.obj" -o "$T/dv2.s" 2>/dev/null
"$A" "$T/dv2.s" -o "$T/dv2.obj" >/dev/null 2>&1
dn=$(( ($(wc -c < "$T/dv.obj") / 80 - 1) * 80 ))
head -c $dn "$T/dv.obj" > "$T/dv.cut"; head -c $dn "$T/dv2.obj" > "$T/dv2.cut"
cmp -s "$T/dv.cut" "$T/dv2.cut" && pass "round trip: derived hints applied still reassemble byte-identically" \
                                || fail "round trip: derived hints applied still reassemble byte-identically"

# #382's third acceptance, and the one that cannot be faked. PAD expands to a
# different LENGTH in maclib-a and maclib-b, so every label after it shifts. A
# hint set derived against the wrong library is a wrong hint set that looks
# entirely right -- so the two files must differ VISIBLY.
"$D" --derive-hints tests/derivemac.s --as370 "$A" -I tests/maclib-a -o "$T/ma.toml" 2>/dev/null
"$D" --derive-hints tests/derivemac.s --as370 "$A" -I tests/maclib-b -o "$T/mb.toml" 2>/dev/null
if cmp -s "$T/ma.toml" "$T/mb.toml"; then
    fail "a hint set derived against the wrong -I is visibly different"
else
    pass "a hint set derived against the wrong -I is visibly different"
fi
grep -q 'maclib-a' "$T/ma.toml" && grep -q 'maclib-b' "$T/mb.toml" \
    && pass "and each file names the library it was built with" \
    || fail "and each file names the library it was built with"

# The anchors. Applied to the OTHER library's module, they must locate the
# divergence -- which for these two is the macro at X'6'.
"$A" tests/derivemac.s -I tests/maclib-b -o "$T/mb.obj" >/dev/null 2>&1
rm -f "$T/an.s"
"$D" --hints "$T/ma.toml" "$T/mb.obj" -o "$T/an.s" >/dev/null 2>&1
if [ $? = 16 ] && [ ! -e "$T/an.s" ]; then
    pass "--anchors=refuse is the default: a failed anchor refuses and writes nothing"
else
    fail "--anchors=refuse is the default: a failed anchor refuses and writes nothing"
fi
"$D" --anchors=report --format free --hints "$T/ma.toml" "$T/mb.obj" -o "$T/an.s" 2>/dev/null
rcan=$?
if [ $rcan = 0 ] && grep -q '^\* ANCHOR FAILED 000006' "$T/an.s"; then
    pass "--anchors=report disassembles anyway and names the divergence at its offset"
else
    fail "--anchors=report disassembles anyway and names the divergence at its offset (rc $rcan)"
    sed -n 1,8p "$T/an.s"
fi

# The module's own names outrank a derived one, and disagreeing with them is a
# finding. 409 of the caller's 2,292 length-differing modules carry named
# offsets, so this fires on 18 % of the target population and is silent on the
# rest -- a complement to the anchors, not a substitute.
sed 's/^DERENT   BALR  12,0$/         BALR  12,0\
DERENT   DS    0H/' tests/derive.s > "$T/moved.s"
"$A" "$T/moved.s" -o "$T/moved.obj" >/dev/null 2>&1
rm -f "$T/mv.s"
"$D" --hints "$DH.toml" "$T/moved.obj" -o "$T/mv.s" >"$T/mv.err" 2>&1
if [ $? = 16 ] && [ ! -e "$T/mv.s" ] && grep -q "X'2' in this module and X'0' in the hint file" "$T/mv.err"; then
    pass "an ENTRY at a different offset than the derived label refuses, naming both"
else
    fail "an ENTRY at a different offset than the derived label refuses, naming both"
    cat "$T/mv.err"
fi

"$D" --derive-hints tests/derive.s --as370 "$A" "$T/dv.obj" >/dev/null 2>&1
[ $? = 16 ] && pass "--derive-hints with a deck as well is refused -- it assembles its own" \
            || fail "--derive-hints with a deck as well is refused -- it assembles its own"
"$D" --derive-hints tests/derive.s --as370 "$A" --hints "$DH.toml" >/dev/null 2>&1
[ $? = 16 ] && pass "--derive-hints WRITES a hint file and refuses to also read one" \
            || fail "--derive-hints WRITES a hint file and refuses to also read one"

# ---- --anchors=report means report, for EVERY detector --------------------
# Measured by the caller over the 2,292 length-differing CSECTs: of 634 refused
# applications, 404 were a derived base's range overflowing a SHORTER section --
# which is the population's defining property, not an error -- and 158 were the
# label collision detector firing, which is a divergence report with both
# offsets in it. 562 of 634 were measurements being refused instead of reported,
# and fixing that took the usable population from 1,055 to 1,617.
#
# So: refuse stays the default and stays right for a hand-written file. Under
# report every detector reports, the run continues, and the finding is a comment
# at its offset where it has one.
cat > "$T/short.s" <<'EOF'
* a DERIVE section far shorter than the one the hints came from
DERIVE   CSECT
DERENT   BALR  12,0
         USING *,12
         BR    14
         END   DERENT
EOF
"$A" "$T/short.s" -o "$T/short.obj" >/dev/null 2>&1
rm -f "$T/sr.s"
"$D" --hints "$DH.toml" "$T/short.obj" -o "$T/sr.s" >/dev/null 2>&1
[ $? = 16 ] && [ ! -e "$T/sr.s" ] \
    && pass "a shorter module still REFUSES by default -- a hand-written file's ranges are assertions" \
    || fail "a shorter module still REFUSES by default"
"$D" --anchors=report --format free --hints "$DH.toml" "$T/short.obj" -o "$T/sr.s" 2>/dev/null
rcsr=$?
srwant() { if grep -qE "$1" "$T/sr.s"; then pass "$2"; else fail "$2"; fi; }
[ $rcsr = 0 ] && pass "under report a shorter module is disassembled anyway" \
              || fail "under report a shorter module is disassembled anyway (rc $rcsr)"
srwant '^\* HINTS REPORT: [0-9]+ anchor' "a summary line, because a run over a population is read by the hundred"
srwant 'clamped, and' "a base overruning the section is CLAMPED and says so -- 404 of the caller's 634"
srwant "anchor at X'1A' is past the end" "an anchor past the end is the measurement, not an error"
srwant "label .LOOPTOP. at X'6' is past the end" "and so is a label past the end"

# The collision detector under report: both offsets, and the hint label DROPPED.
# Clearing lab[] alone left the name findable and the disassembly carried it at
# BOTH offsets -- the duplicate symbol the detector exists to prevent,
# reintroduced by the detector's own report path.
"$D" --anchors=report --format free --hints "$DH.toml" "$T/moved.obj" -o "$T/mr.s" 2>/dev/null
if grep -qE "^\* .DERENT. is at X'2' in this module and X'0' in the hint file" "$T/mr.s"; then
    pass "under report a label collision is a divergence report with both offsets"
else
    fail "under report a label collision is a divergence report with both offsets"
fi
if [ "$(grep -c '^DERENT ' "$T/mr.s")" = 1 ]; then
    pass "and the hint's name is dropped, so one symbol is not emitted at two offsets"
else
    fail "and the hint's name is dropped, so one symbol is not emitted at two offsets"
    grep -n '^DERENT ' "$T/mr.s"
fi
# A note carries two offsets, so a note cut at column 71 is a note whose second
# offset is gone. Wrapped, never truncated -- and still 80 columns in card form.
"$D" --anchors=report --hints "$DH.toml" "$T/moved.obj" -o "$T/mc.s" 2>/dev/null
if [ "$(awk '{ if (length($0) != 80) n++ } END { print n+0 }' "$T/mc.s")" = 0 ] \
   && [ "$(awk '{ if (substr($0,72,1) != " ") n++ } END { print n+0 }' "$T/mc.s")" = 0 ]; then
    pass "a wrapped comment is still 80 columns with column 72 blank"
else
    fail "a wrapped comment is still 80 columns with column 72 blank"
fi

# ---- --infer (#382, PR C) -------------------------------------------------
# Candidates from the code itself, for the CSECT with no source at all -- the
# 772 of #112, mostly reachable only from a bound member.
#
# EVERY CANDIDATE IS A COMMENT AND NONE IS APPLIED, which is the issue's
# instruction and not caution: a base register is not "R12 holds X" but "from
# here until it is dropped". The POINT is sometimes ground truth; the RANGE
# never is, because a module has no DROPs and no block structure to read one
# from. Get the range wrong and every displacement inside it resolves against
# the wrong section -- plausibly, consistently, falsely, without moving a byte.
"$A" tests/infer.s -o "$T/inf.obj" >/dev/null 2>&1
"$D" --infer "$T/inf.obj" -o "$T/inf.toml" 2>/dev/null
iwant() { if grep -qE "$1" "$T/inf.toml"; then pass "$2"; else fail "$2"; fi; }
iwant 'reg=12 value=0x2 at=0x0 evidence=prologue' \
      "BALR 12,0 is a PROLOGUE base -- exact about where, silent about how long"
iwant 'reg=9 value=0x18 at=0x2 evidence=rld' \
      "a register loaded from an A-con the RLD resolves into this section is RLD evidence"
iwant 'reg=7 value=\? at=\? evidence=pattern .*no-origin-found' \
      "a register used as a base with no origin is a PATTERN -- a question, not an answer"

# The three kinds differ in what a later reader can re-judge them against, which
# is why the kind is recorded separately from any confidence: rld is checkable
# against the object, pattern against nothing at all.
[ "$(grep -c '^# infer:' "$T/inf.toml")" = 3 ] \
    && pass "three candidates, one of each kind" \
    || fail "three candidates, one of each kind"
if grep -qE '^\[\[' "$T/inf.toml"; then
    fail "--infer writes NO applicable table -- every candidate is a comment"
else
    pass "--infer writes NO applicable table -- every candidate is a comment"
fi

# Fed back to --hints it must change NOTHING. That is what "written, never
# applied" means operationally, and a table would break it.
"$D" --format free "$T/inf.obj" -o "$T/inf-plain.s" 2>/dev/null
"$D" --format free --hints "$T/inf.toml" "$T/inf.obj" -o "$T/inf-hint.s" 2>/dev/null
cmp -s "$T/inf-plain.s" "$T/inf-hint.s" \
    && pass "the inferred file fed back to --hints changes not one byte of the output" \
    || { fail "the inferred file fed back to --hints changes not one byte of the output"
         diff "$T/inf-plain.s" "$T/inf-hint.s" | head -4; }

"$D" --infer --derive-hints tests/derive.s "$T/inf.obj" >/dev/null 2>&1
[ $? = 16 ] && pass "--infer and --derive-hints together are refused -- two producers of one file" \
            || fail "--infer and --derive-hints together are refused"

# ---- refusals -------------------------------------------------------------
"$D" --csect NOSUCHCS "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 2 ] && pass "an unknown --csect exits 2, not 0" || fail "an unknown --csect exits 2, not 0"
"$D" --isa nonsense "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 16 ] && pass "an --isa value that is not one of the four is refused" \
             || fail "an --isa value that is not one of the four is refused"

[ $fails = 0 ] && echo "dasm370: all checks passed" || echo "dasm370: $fails FAILURE(S)"
exit $fails
