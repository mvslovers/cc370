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
L=../ld370/ld370
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
iwant 'reg=9 value=0x28 at=0x2 evidence=rld' \
      "a register loaded from an A-con the RLD resolves into this section is RLD evidence"
iwant 'reg=7 value=\? at=\? evidence=pattern .*no-origin-found' \
      "a register used as a base with no origin is a PATTERN -- a question, not an answer"

# The three kinds differ in what a later reader can re-judge them against, which
# is why the kind is recorded separately from any confidence: rld is checkable
# against the object, pattern against nothing at all.
iwant 'reg=5 .*evidence=pattern used=no note=balr-not-used-as-base' \
      "a BALR whose register is never used as a base is NOT claimed as a prologue"
# The R2 == 0 guard: BALR 1,15 is X'051F' and is a call, not addressability.
# The caller's ICKTR02 case was read as this guard failing; it is not -- the
# guard is correct, and what produced that candidate is the line below.
# TWO phantoms, one mechanism, and the DECIMAL one is the real case: ICKTR02
# carries DC F'01296', and decimal 1296 is X'00000510' -- the low half of an
# ordinary fullword constant IS the idiom. Nobody reading that card would
# suspect it, which is the whole reason it is in the fixture and not merely
# described. The hex form beside it is the same mechanism written where a
# reader might think to look.
if grep -qE 'reg=1 value=0x20 at=0x1E evidence=prologue' "$T/inf.toml"; then
    pass "a DECIMAL phantom: DC F'1296' is X'00000510', so its low half reads as BALR 1,0"
else
    fail "a DECIMAL phantom: DC F'1296' is X'00000510', so its low half reads as BALR 1,0"
fi
if grep -qE 'reg=1 value=0x22 at=0x20 evidence=prologue' "$T/inf.toml"; then
    pass "and the hex form of the same mechanism"
else
    fail "and the hex form of the same mechanism"
fi
# That is a LIMIT and it is pinned deliberately, not a defect to be papered over:
# `BALR Rn,0' is a run-time fact and `USING' an assembly-time declaration, and an
# object records the first and cannot record the second. Only reachability (#383)
# can say nothing branches into that table. When #383 lands this assertion should
# fail and be updated on purpose, exactly as as370's bare-DROP fixture did.
[ "$(grep -c '^# infer:' "$T/inf.toml")" = 6 ] \
    && pass "six candidates: prologue, rld, pattern, a BALR that is neither, and two phantoms" \
    || fail "six candidates: prologue, rld, pattern, a BALR that is neither, and two phantoms"

# THE BLOCKER #401 was held on, and it is the property the mode exists for: the
# 772 no-source CSECTs are reachable only from a BOUND MEMBER. --infer sat before
# the emit_source label, which the member path reaches by goto -- so a deck fell
# through and produced candidates while a member jumped past and produced an
# ordinary disassembly with none in it, which reads exactly like a module that
# has none. Measured by the caller: 374 candidates from 30 CSECTs' decks, 0 from
# the same CSECTs' members (IEAVTCR1 is identical, so the bytes were the same),
# and 648 of 648 no-source CSECTs silent.
"$L" -o "$T/inf.lm" --name INFER "$T/inf.obj" >/dev/null 2>&1
if [ -s "$T/inf.lm" ]; then
    "$D" --infer "$T/inf.obj" 2>/dev/null | grep '^# infer:' > "$T/cd.txt"
    "$D" --infer "$T/inf.lm"  2>/dev/null | grep '^# infer:' > "$T/cm.txt"
    if [ -s "$T/cm.txt" ] && cmp -s "$T/cd.txt" "$T/cm.txt"; then
        pass "a BOUND MEMBER yields the same candidates as the deck -- the only form the 772 exist in"
    else
        fail "a BOUND MEMBER yields the same candidates as the deck"
        echo "  deck:"; sed -n 1,4p "$T/cd.txt"; echo "  member:"; sed -n 1,4p "$T/cm.txt"
    fi
else
    fail "a BOUND MEMBER yields the same candidates as the deck (ld370 produced nothing)"
fi
if grep -qE '^\[\[' "$T/inf.toml"; then
    fail "--infer writes NO applicable table -- every candidate is a comment"
else
    pass "--infer writes NO applicable table -- every candidate is a comment"
fi

# ---- an F_S0's tail is not a field ---------------------------------------
# An S-format opcode with NO OPERAND is four bytes wide and the last two are
# ignored by the hardware. What dasm370 emits for one is the bare mnemonic, and
# as370 assembles that to <op>0000 -- so a PTLB whose tail is not zero cannot be
# written as `PTLB' without losing two bytes.
#
# reencode_ok() compared the decode against THE BYTES IT WAS READ FROM, so for
# an F_S0 it compared the input with itself and passed on any tail at all. The
# comparison has to be against what the STATEMENT assembles to.
#
# Found by the caller as a case, not a diagnosis: IFOX51's IFNX5M00 at 000A1A,
# `B20D 28B2', the ONE module of 599 whose round trip caught anything. The fix
# moves exactly 1 of 649 readable sections, and that one now round-trips.
#
# The first version of the fix put the guard inside the F_S/F_S0 arm of
# reencode_ok and CHANGED NOTHING: an F_S0's opcode is two bytes wide, so the
# `opw == 2' arm claims it first. A guard in an unreachable branch is a guard
# that reports success.
# The adcon is not decoration: a DC run swallows up to sixteen bytes, so without
# something that breaks it the bad four bytes take the good four with them and
# the control below cannot fire. An address constant breaks the run.
cat > "$T/s0.s" <<'ASM'
S0TAIL   CSECT
         DC    X'B20D0000'
         BR    14
         DC    A(S0TAIL)
         DC    X'B20D28B2'
         END
ASM
"$A" "$T/s0.s" -o "$T/s0.obj" >/dev/null 2>&1 || fail "the F_S0 fixture does not assemble"
"$D" --format free "$T/s0.obj" > "$T/s0.txt" 2>/dev/null
if grep -q "B20D28B2" "$T/s0.txt"; then
    pass "an F_S0 with a non-zero tail is DC -- the mnemonic would lose two bytes"
else
    fail "an F_S0 with a non-zero tail is DC -- the mnemonic would lose two bytes"
    sed -n 2,6p "$T/s0.txt"
fi
# THE CONTROL, and without it the assertion above is satisfied by refusing every
# PTLB: a zero tail IS writable as the mnemonic and must still decode.
if grep -qE '(^|[^A-Z0-9])PTLB( |$)' "$T/s0.txt"; then
    pass "and an F_S0 with a zero tail still decodes as the mnemonic"
else
    fail "and an F_S0 with a zero tail still decodes as the mnemonic"
    sed -n 2,6p "$T/s0.txt"
fi

# ---- a refusal that names what it DID find --------------------------------
# By the time dasm370 says "no section named X" the CESD walk has already stored
# every LD/LR entry and every ESD name -- so when it refused AHLDMPMD it already
# knew AHLDMPMD is an ENTRY POINT owned by the section AHLWTO in that very
# member, and said none of it.
#
# THE REFUSAL ASSERTED LESS THAN THE TOOL KNEW, and that is not cosmetic: the
# caller read it as "wrong member", went looking for a lookup failure, and wrote
# 124 modules up as an unresolved corpus. Of those 124, measured: 0 are a
# section this reader missed, 93 name an entry point whose owning section is in
# the same member, 29 name a deleted CESD entry, 2 are genuinely absent. One
# message separates them at the first run.
cat > "$T/ent.s" <<'ASM'
SECTA    CSECT
         ENTRY EPX
         BALR  12,0
         USING *,12
EPX      LR    1,1
         BR    14
         END
ASM
"$A" "$T/ent.s" -o "$T/ent.obj" >/dev/null 2>&1 || fail "the ENTRY fixture does not assemble"
"$D" --csect EPX "$T/ent.obj" >/dev/null 2>"$T/ent.err"; rc=$?
if [ "$rc" = 2 ] && grep -q 'ENTRY POINT' "$T/ent.err" && grep -q 'SECTA' "$T/ent.err"; then
    pass "asking for an ENTRY POINT is refused by NAMING it and its section"
else
    fail "asking for an ENTRY POINT is refused by NAMING it and its section (rc $rc)"
    cat "$T/ent.err"
fi
"$D" --csect NOSUCH "$T/ent.obj" >/dev/null 2>"$T/no.err"; rc=$?
if [ "$rc" = 2 ] && grep -q 'it holds SECTA' "$T/no.err"; then
    pass "a name that is nowhere is refused by listing the sections that ARE there"
else
    fail "a name that is nowhere is refused by listing the sections that ARE there (rc $rc)"
    cat "$T/no.err"
fi
# The exit code does not move: a refusal is still a refusal, and a caller
# branching on rc must see no change at all.
[ "$rc" = 2 ] && pass "and the exit code is unchanged -- only the message says more" \
              || fail "and the exit code is unchanged -- only the message says more"

# ---- --labels sequential (#396) ------------------------------------------
# A LIE THAT ASSEMBLES, and that is the whole issue. A label named after the
# offset it sits at -- L0000A4 for X'A4' -- is wrong the moment a statement is
# inserted above it: the name still reads L0000A4 and it now sits at X'A6'. No
# diagnostic, no moved byte, so it is invisible to the round trip, to
# cmplmd370, to reachgate.py and to --align-diff. Every instrument this project
# has reports success on it.
#
# Inserting statements is the caller's repair workflow, not a hypothetical.
#
# SO THE TEST CANNOT BE A ROUND TRIP. It edits the disassembly the way a repair
# would and then asks AS370'S OWN SYMBOL TABLE where each label actually
# landed -- an independent instrument, and the only kind that can see this.
#
# Mutant scores, and two of the three are ZERO and are recorded as zero:
#
#   the control itself                                    fires, 4 of 4
#       ... one two-byte insertion and every generated label in the file
#       names an address it does not occupy. If that count were 0 the whole
#       block would be measuring nothing.
#   sequential falls back to the displacement name when the        0 fail
#   binary search misses
#       ... UNEXERCISED, and by construction: every offset label_name is
#       called with was put in lab[] by the same pass that numbers it, so
#       the fallback is unreachable. It is kept because a future caller of
#       label_name need not hold that property, and it is honest to say the
#       suite does not test it.
#   the numbering moved BEFORE the scanning passes settle         0 fail
#       ... a VALID mutant -- the binary changes -- and no fixture catches
#       it. The rule is that a hint USING plants BC targets over up to eight
#       passes, so numbering early leaves a late target unnumbered. The
#       hinted fixture below does not plant a NEW label in a later pass, so
#       nothing here fires. Stated rather than scored: what would exercise it
#       is a [[base]] whose BC target is named by nothing else in the module.
"$A" tests/reach.s -o "$T/lab.obj" >/dev/null 2>&1 || fail "reach.s does not assemble"
labtest() {
    "$D" --labels "$1" --format card "$T/lab.obj" -o "$T/lab-$1.s" 2>/dev/null
    # one two-byte instruction inserted after the CSECT card, column 72 left
    # blank -- a card that reaches it eats the next one, at severity 4
    awk 'NR==1{print; printf "%-8s %-5s %-56s %8s\n","","LR","1,1","00000050"; next} {print}' \
        "$T/lab-$1.s" > "$T/lab-$1-e.s"
    "$A" "$T/lab-$1-e.s" --sym="$T/lab-$1.tsv" -o /dev/null >/dev/null 2>&1
    awk -F'\t' '$1 ~ /^L[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$/ {
        n = 0; h = substr($1,2)
        for (i = 1; i <= 6; i++) { c = index("0123456789ABCDEF", substr(h,i,1)) - 1; n = n*16 + c }
        if (n != $2 + 0) bad++
    } END { print bad + 0 }' "$T/lab-$1.tsv"
}
lied=$(labtest displacement)
honest=$(labtest sequential)
if [ "$lied" -ge 1 ]; then
    pass "a displacement-derived label LIES after an insertion ($lied of them here)"
else
    fail "a displacement-derived label LIES after an insertion -- the control did not fire"
fi
if [ "$honest" = 0 ]; then
    pass "a sequential label makes no address claim, so an insertion cannot falsify it"
else
    fail "a sequential label makes no address claim, so an insertion cannot falsify it"
fi

# And it must move no byte: the names change, the object does not. Compared the
# way the round trip above does it -- every card before the END, whose optional
# IDR legitimately differs.
"$D" --labels sequential --format card "$T/lab.obj" -o "$T/lab-seq.s" 2>/dev/null
"$A" "$T/lab-seq.s" -o "$T/lab-seq.obj" >/dev/null 2>&1
ln=$(( ($(wc -c < "$T/lab.obj") / 80 - 1) * 80 ))
head -c $ln "$T/lab.obj" > "$T/lab-a.cut"
head -c $ln "$T/lab-seq.obj" > "$T/lab-b.cut"
if cmp -s "$T/lab-a.cut" "$T/lab-b.cut"; then
    pass "sequential labels reassemble to the same bytes"
else
    fail "sequential labels reassemble to the same bytes"
fi
if grep -qE '^L[0-9A-F]{6} ' "$T/lab-seq.s"; then
    fail "no displacement-shaped label survives --labels sequential"
else
    pass "no displacement-shaped label survives --labels sequential"
fi
"$D" --labels nonsense "$T/lab.obj" >/dev/null 2>&1
[ $? = 16 ] && pass "--labels with an unknown mode is refused" \
             || fail "--labels with an unknown mode is refused"

# THE NUMBERING MUST RUN AFTER THE LABELS SETTLE, and only a hint USING can show
# it: a [[base]] gives BC targets a meaning, and those are planted over up to
# eight scanning passes. Number before they settle and a target found in pass 2
# is not in the ordering, falls back to the displacement name, and the assertion
# below catches it -- the same assertion, on a disassembly that has hints.
"$D" --labels sequential --hints "$H.using" "$T/a.obj" -o "$T/lab-h.s" 2>/dev/null
if grep -qE '^L[0-9A-F]{6} ' "$T/lab-h.s"; then
    fail "a branch target found by a later scanning pass is numbered, not left as a displacement"
    grep -E '^L[0-9A-F]{6} ' "$T/lab-h.s" | head -2
else
    pass "a branch target found by a later scanning pass is numbered, not left as a displacement"
fi

# ---- --reach-report (#383) -----------------------------------------------
# The traversal's coverage as data. THE APPLIED FORM IS NOT SHIPPED and that is
# a measurement, not caution: over the caller's 30 control CSECTs it darkens
# 12,558 bytes their source listing calls CODE against 2,300 bytes of genuine
# table it correctly silences, and the best threshold on its own coverage is
# break-even. Byte-safe is not harmless -- a module whose real code becomes DC
# round-trips identically and every gate reports success. cc370#383 has it.
#
# tests/reach.s is a known-answer module in a PL/S shape: a branch over an
# eyecatcher through R15, a prologue BALR, that base copied by LR, and a jump
# table reached by loading a register from relocated words and branching
# through it. It carries BOTH cases the deliverable separates -- TAB, promoted
# because a register loaded from it IS branched through, and DTAB, an address
# constant pointing at the eyecatcher that is loaded and never branched
# through, which must stay a LABEL root.
#
# SCORED AGAINST MUTANTS, because every rule here is a rule:
#
#   the promotion anchored strictly on the load's target        2 fail
#       ... TABZ is index 0, holds zero and carries no relocation, so the
#       run must be taken from the target OR the word after it. Measured on
#       BLSCAMER first, whose own table begins the same way.
#   the promotion at the LOAD instead of at the BR (no gate)    1 fail
#       ... DTAB is then promoted, `acon' goes 2 -> 5 over 3 tables, and the
#       first reached run swallows the EYECATCHER -- which is exactly the
#       `DC A(BUFFER)' case #383's first bullet forbids, in one line of
#       output. The discriminator is the BR and not the adcon.
#   bases pre-scanned instead of discovered by the walk       (corpus only)
#       ... invisible here; on the corpus it adopts six halfwords in
#       BLSCAMER's DATA that decode as prologues, and cost IECVERPL its
#       real LR base.
"$A" tests/reach.s -o "$T/reach.obj" >/dev/null 2>&1 || fail "reach.s does not assemble"
rfield() { "$D" --reach-report="$2" "$T/reach.obj" 2>/dev/null | head -1 | tr ' ' '\n' | grep "^$1=" | cut -d= -f2; }
rruns() { "$D" --reach-report="$2" "$T/reach.obj" 2>/dev/null | grep '^REACHRUN'; }

# The SD root alone, with no base at all: the section origin and nothing more.
# `B START(0,15)' cannot be followed without R15, so the walk dies at byte 4.
[ "$(rfield reached none)" = 4 ] \
    && pass "with no base the traversal reaches the SD root and stops at the first branch" \
    || fail "with no base the traversal reaches the SD root and stops at the first branch"

# THE EYECATCHER IS THE WHOLE POINT. Without reachability it decodes as MVCK
# and STH -- text that re-encodes perfectly and that no opcode gate can refuse.
if rruns all | awk '{o=strtonum("0x"$2); if (o < 0x12 && o+$3 > 0x04) f=1} END{exit !f}'; then
    fail "the eyecatcher stays dark -- nothing branches into it"
else
    pass "the eyecatcher stays dark -- nothing branches into it"
fi

# Dead code after an unconditional branch, which nothing enters.
if rruns all | awk '{o=strtonum("0x"$2); if (o < 0x32 && o+$3 > 0x28) f=1} END{exit !f}'; then
    fail "code after an unconditional branch that nothing enters stays dark"
else
    pass "code after an unconditional branch that nothing enters stays dark"
fi

# The promotion, and the two halves of it the deliverable separates.
if [ "$(rfield acon all)" = 2 ] && [ "$(rfield acontab all)" = 1 ]; then
    pass "a register loaded from a relocated table and BRANCHED THROUGH promotes it"
else
    fail "a register loaded from a relocated table and BRANCHED THROUGH promotes it"
    "$D" --reach-report=all "$T/reach.obj" | head -1
fi
[ "$(rfield reached bothlr)" -lt "$(rfield reached all)" ] \
    && pass "and the promotion is what reaches the jump table's targets" \
    || fail "and the promotion is what reaches the jump table's targets"

# THE OTHER HALF, and it is the first bullet: DTAB points at the eyecatcher and
# is loaded, and no register loaded from it is branched through. The eyecatcher
# assertion above is what fails if that gate is removed -- an RLD target is a
# LABEL root, and the discriminator is the BR and not the adcon.
[ "$(rfield rldbase all)" -ge 1 ] \
    && pass "an adcon loaded but never branched through sets a base and promotes NOTHING" \
    || fail "an adcon loaded but never branched through sets a base and promotes NOTHING"

# The applied form is refused by name rather than silently absent.
"$D" --reach "$T/reach.obj" >/dev/null 2>&1
[ $? = 16 ] && pass "--reach (applied) is refused, and says what the measurement was" \
            || fail "--reach (applied) is refused, and says what the measurement was"

# ---- --align-diff (#384) -------------------------------------------------
# Both sides disassembled and aligned statement by statement, so a displacement
# that moved because something before it changed length is reported as a
# CONSEQUENCE rather than as a change of its own.
#
# THE FIXTURES ARE TWO CONSTRUCTED CASES AND EACH CORRECTED THE DESIGN ONCE.
# align-a.s is the reference; align-b.s adds one 4-byte instruction; align-c.s
# adds two of 2 and 4 bytes.  Their headers say what each is for.
#
# SCORED AGAINST MUTANTS, because most of what this mode does is a RULE and a
# rule cannot be demonstrated by a fixture that passes.  Each was mutated out of
# dasm370.c and the suite re-run, with a rebuild guard on the binary's sha256:
#
#   mask_disp() made a no-op                                    3 fail
#       ... the key stops surviving a shift, so every statement after an
#       insertion reads as its own change.
#   the section end left out of the shift set                   1 fail
#       ... case 2 exactly: the 2 bytes of alignment padding sit inside the
#       trailing data run, which does not match, so no matched pair carries
#       +8 and all four displacements come back as constant changes.
#   the hole-to-zero fill in align_load() dropped               0 fail HERE,
#       and 19 of the caller's 30 control CSECTs disagree with cmplmd370.
#       Both fixtures are decks, so nothing here can see it: a deck says
#       which bytes no TXT card covered and a bound member cannot, because
#       the binder filled them.  A corpus mutant score, deliberately.
#   adjacent data statements not merged into one run            0 fail HERE,
#       0 of the 30, and 48,275 findings against 48,862 over the caller's
#       140 eyecatcher modules -- 1.2 %.  SO IT IS A REPORT-SHAPE RULE AND
#       NOT A CORRECTNESS ONE, and it is written down here because the
#       opposite was expected: the reasoning was that walk_section cuts a DC
#       run at 16 bytes and a shifted data area would re-chunk.  It does not,
#       because the cut is 16 bytes FROM THE RUN'S OWN START, so a pure shift
#       carries its chunk boundaries with it.  What merging buys is that a
#       changed data region is ONE finding rather than one per card.
for f in a b c; do
    "$A" "tests/align-$f.s" -o "$T/al$f.obj" >/dev/null 2>&1 || fail "align-$f.s does not assemble"
done
asum() { grep -m1 '^SUMMARY' "$1" | tr ' ' '\n' | grep "^$2=" | cut -d= -f2; }

# The null control, and it is one this mode can fail: a classifier that invents
# a shift between two identical sections fails here and nowhere else.
"$D" --align-diff "$T/ala.obj" "$T/ala.obj" -o "$T/aln.txt" 2>/dev/null
if [ "$(asum "$T/aln.txt" findings)" = 0 ] && [ "$(asum "$T/aln.txt" conseq)" = 0 ] \
   && [ "$(asum "$T/aln.txt" shifts)" = 1 ]; then
    pass "a section against ITSELF: no finding, no consequence, one shift value"
else
    fail "a section against ITSELF: no finding, no consequence, one shift value"
    grep '^SUMMARY' "$T/aln.txt"
fi

# The SUMMARY line is the only machine-readable thing a population run leaves, so
# its denominators are asserted rather than assumed: a finding count over 832
# modules cannot be normalised without a size, and `first' is what a triage run
# ranks on.  `first=-' where there is no finding, because an absent offset must
# not read as offset zero.
if grep -q '^SUMMARY ALIGNX .* first=- refstmt=7 candstmt=7 reflen=28 candlen=28 ' "$T/aln.txt"; then
    pass "SUMMARY carries its own denominators, and no finding is first=- not first=000000"
else
    fail "SUMMARY carries its own denominators, and no finding is first=- not first=000000"
    grep '^SUMMARY' "$T/aln.txt"
fi

# Case 1.  One insertion, and the four displacements that follow it are
# consequences -- but the FIRST of them is at 000002 and the insertion is at
# 00000A.  #112 states the caller's assumption as "the shifts FOLLOWING an
# attributed length change are consequences"; this shift precedes its own cause,
# because the instruction addresses data past the insertion point and inserting
# anywhere before that data moves it.  So the classifier must not use position
# relative to the change as evidence, and this fixture is what says so.
"$D" --align-diff "$T/ala.obj" "$T/alb.obj" -o "$T/al1.txt" 2>/dev/null
if [ "$(asum "$T/al1.txt" ins)" = 1 ] && [ "$(asum "$T/al1.txt" findings)" = 1 ] \
   && [ "$(asum "$T/al1.txt" const)" = 0 ]; then
    pass "one insertion is ONE finding, and the shifts around it are consequences"
else
    fail "one insertion is ONE finding, and the shifts around it are consequences"
    grep '^SUMMARY' "$T/al1.txt"
fi
if grep -q '^SUMMARY ALIGNX .* first=00000A ' "$T/al1.txt"; then
    pass "first= is the first FINDING's offset, not the first consequence's"
else
    fail "first= is the first FINDING's offset, not the first consequence's"
    grep '^SUMMARY' "$T/al1.txt"
fi
if grep -q '^CONSEQ  shift  000002 -> 000002' "$T/al1.txt" \
   && grep -q '^FINDING insert ref 00000A' "$T/al1.txt"; then
    pass "a shift at 000002 PRECEDES its cause at 00000A -- position is not evidence"
else
    fail "a shift at 000002 PRECEDES its cause at 00000A -- position is not evidence"
    grep -E '^(CONSEQ|FINDING)' "$T/al1.txt"
fi

# Case 2.  Six bytes of code inserted, EIGHT bytes of displacement movement: the
# 2-byte insertion pushed the data area off its fullword boundary and the
# assembler made up the difference.  A prefix sum over the detected insertions
# gives 6, so a classifier built that way reports all four displacements as
# constant changes -- a whole module of findings where there are none.  The shift
# function is computed from the ALIGNMENT instead, which counts every statement,
# code and data alike, and the padding falls out for free.
"$D" --align-diff "$T/ala.obj" "$T/alc.obj" -o "$T/al2.txt" 2>/dev/null
if [ "$(asum "$T/al2.txt" const)" = 0 ] && grep -q '  D1 18 -> 26  +8$' "$T/al2.txt"; then
    pass "6 bytes inserted, 8 of movement: the alignment padding is a CONSEQUENCE too"
else
    fail "6 bytes inserted, 8 of movement: the alignment padding is a CONSEQUENCE too"
    grep -E '^(CONSEQ|FINDING|  shift set)' "$T/al2.txt"
fi

# Refused rather than combined.  A hint file supplies the base this mode says it
# does not have -- a real refinement, and a later one; combining them now would
# report two different shift(B) cases from one run without saying which applied
# where.  And the mode names both objects itself, so a third is a mistake.
"$D" --align-diff "$T/ala.obj" "$T/alb.obj" --hints /dev/null -o "$T/x.txt" 2>/dev/null
[ $? = 16 ] && pass "--align-diff with --hints is refused" || fail "--align-diff with --hints is refused"
"$D" --align-diff "$T/ala.obj" "$T/alb.obj" "$T/alc.obj" -o "$T/x.txt" 2>/dev/null
[ $? = 16 ] && pass "--align-diff with a third object is refused" || fail "--align-diff with a third object is refused"
"$D" --align-diff "$T/ala.obj" 2>/dev/null
[ $? = 16 ] && pass "--align-diff with one object is refused" || fail "--align-diff with one object is refused"

# ---- --json, the repair contract (#385) ----------------------------------
# JSON per divergence, and DELIBERATELY THE OBJECT-SIDE HALF OF IT. Three of the
# five fields #385 specifies are LISTING facts with no machine-readable export:
# the owning statement's source line and text, whether it is macro-generated and
# which call owns it, and whether a statement RESERVES bytes (DS CL1) or only
# ALIGNS (DS 0F).
#
# The last settles the question and it was measured, not argued: IN AN OBJECT
# BOTH ARE UNCOVERED BYTES. Two defensible object-side rules over the caller's 30
# control CSECTs, against 13,161 bytes with no object code, give 89 bytes and
# 1,788 -- ONE PER CENT AGAINST FOURTEEN. Two methods that cannot agree on the
# SIZE of the population is what "a source fact" means once it is measured.
#
# So every finding carries source:null WITH A REASON. A schema that omitted the
# key would read as though the question had not come up.
#
# Mutant scores, and the two zeros are recorded as zeros:
#
#   source_absent_because dropped from the document            2 fail
#       ... the REASON is hoisted to document level, because it is a property
#       of the build and not of the finding: 265 characters on each of
#       120,163 findings is 31.8 MB of 77.5, two fifths of the corpus output
#       and identical in every record. What stays per finding is
#       `source_absent: "no-statement-export"' -- nine characters, so a
#       consumer can still hold one finding in its hand.
#   the counts block dropped from the document                3 fail
#   jstr() stops escaping the quote and the backslash         0 fail
#       ... UNEXERCISED here and nearly unreachable: dasm370's own operands
#       carry apostrophes (X'..') and never a double quote or a backslash,
#       which are the only two characters JSON needs escaped. The reachable
#       case is a PATH containing one, and no fixture has such a path.
#
# And one rule was REMOVED rather than tested, because measuring it showed it
# could not fire: `bytes' had a `..' marker for a byte no TXT card covered, and
# align_load() fills every such byte with zero before collecting. 0 of 240,326
# byte fields over the caller's 832 modules carried one. A first grep said 832
# documents contained `..' -- it was matching the schema note's own text.
"$A" tests/align-a.s -o "$T/ja.obj" >/dev/null 2>&1
"$A" tests/align-c.s -o "$T/jc.obj" >/dev/null 2>&1
"$D" --align-diff "$T/ja.obj" "$T/jc.obj" --json "$T/rep.json" -o /dev/null 2>/dev/null
python3 - "$T/rep.json" > "$T/json.out" 2>&1 <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
f = d["findings"]
print("parse ok")
print("count-matches" if len(f) == d["counts"]["findings"] else "count-MISMATCH %d %d" % (len(f), d["counts"]["findings"]))
print("source-null" if all(x[s]["source"] is None and x[s]["source_absent"] == "no-statement-export" for x in f for s in ("ref","cand")) and d["source_absent_because"] else "source-NOT-null")
print("schema-%s" % d["schema"])
print("holes-marked" if any(".." in x[s]["bytes"] for x in f for s in ("ref","cand")) or True else "")
print("has-shift-set" if isinstance(d["shift_set"], list) and d["shift_set"] else "no-shift-set")
print("base-%s" % d["base"])
PY
jwant() { if grep -qx "$1" "$T/json.out"; then pass "$2"; else fail "$2"; cat "$T/json.out"; fi; }
jwant "parse ok"      "the repair contract is valid JSON"
jwant "schema-dasm370-repair/2" "the schema names its version, and /2 is where source moved to the sides"
jwant "count-matches" "the findings array length equals counts.findings"
jwant "source-null"   "every finding carries source:null WITH the reason it is absent"
jwant "has-shift-set" "the shift set travels with the findings -- how strong the test was"

# A byte no TXT card covered is a HOLE and must not read as a zero.
if grep -q '\.\.' "$T/rep.json" || true; then :; fi
"$D" --align-diff "$T/ja.obj" "$T/jc.obj" --json "$T/rep2.json" -o /dev/null 2>/dev/null
if cmp -s "$T/rep.json" "$T/rep2.json"; then
    pass "the contract is reproducible: two runs, one byte-identical document"
else
    fail "the contract is reproducible: two runs, one byte-identical document"
fi

# --json without --align-diff has nothing to describe, and says so.
"$D" --json "$T/x.json" "$T/ja.obj" >/dev/null 2>&1
[ $? = 16 ] && pass "--json without --align-diff is refused by name" \
             || fail "--json without --align-diff is refused by name"

# ---- the two lists in one control record ---------------------------------
# A control record carrying BOTH an ID/length list and RLD info holds the RLD
# FIRST.  Every other record has one or the other, and in those the two orders
# produce identical bytes -- which is why a reader can have the order wrong and
# still be right about every member it has ever been shown.  Reading the list
# first began the RLD parse four bytes late, took the first item's flag and
# address for an R/P pair, and lost the item.
#
# IT IS QUIET, WHICH IS THE POINT OF ASSERTING IT HERE.  A lost adcon comes back
# as DC X'..', which reproduces its own bytes, so the round trip stays green over
# it -- byte-safe, therefore invisible to the gate that would have to fail.
# Measured over 13,102 DLIB and target members: 2,489 records carry both lists,
# 2,489 of them put the list after the RLD info, 0 put it first, and 1,339 of the
# members (10.2 %) carry at least one.  On the real corpus the fix recovered
# 3,237 address constants over 300 affected members and withdrew none.
if python3 ../cmplmd370/tests/mkmember.py rldorder "$T/rldorder.bin" 2>/dev/null; then
    if "$D" --format free "$T/rldorder.bin" 2>/dev/null | grep -q "^         DC    A(L000008) "; then
        pass "an adcon survives a control record that carries BOTH lists"
    else
        fail "an adcon survives a control record that carries BOTH lists"
        "$D" --format free "$T/rldorder.bin" 2>&1 | sed -n 5,7p
    fi
else
    fail "an adcon survives a control record that carries BOTH lists (mkmember failed)"
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

# ---- the repair contract's SOURCE half (cc370#385) ------------------------
# THE ACCEPTANCE #385 ASKS FOR, and the fixtures state it as sharply as it can be
# stated: align-d.s and align-e.s differ only in `PAD DS 0F' against
# `HOLD DS CL2' at the same offset, and THEIR DECKS ARE BYTE-IDENTICAL. So the
# object carries no evidence whatsoever for the distinction -- two object-side
# rules measured over the 30 control CSECTs disagree 1 % against 14 % about the
# size of that population -- and only as370's statement export can answer it.
# Both are diffed against the same align-f.s, giving ONE finding at 000006 on
# each side and OPPOSITE verdicts.
#
# ON THE PRE-CHANGE BINARY every check here fails at rc 16, because --ref-stmts
# and --cand-stmts do not exist there. That is an additive option and not a
# mutant, and the useexp block in as370 says the same thing about its own: an
# option a binary rejects cannot be scored against it.
"$A" tests/align-d.s -o "$T/sd.obj" --stmts="$T/sd.tsv" >/dev/null 2>&1
"$A" tests/align-e.s -o "$T/se.obj" --stmts="$T/se.tsv" >/dev/null 2>&1
"$A" tests/align-f.s -o "$T/sf.obj" --stmts="$T/sf.tsv" >/dev/null 2>&1
cmp -s "$T/sd.obj" "$T/se.obj" \
    && pass "acceptance: DS 0F and DS CL2 at one offset produce BYTE-IDENTICAL decks" \
    || { fail "the two decks must be byte-identical or the fixture proves nothing"
         cmp "$T/sd.obj" "$T/se.obj" | head -2; }
for q in d e; do
    "$D" --align-diff "$T/s$q.obj" "$T/sf.obj" --json "$T/s$q.json" \
         --ref-stmts "$T/s$q.tsv" --cand-stmts "$T/sf.tsv" -o /dev/null 2>"$T/s$q.err"
done
python3 - "$T/sd.json" "$T/se.json" > "$T/s.out" 2>&1 <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); e = json.load(open(sys.argv[2]))
def one(j):
    f = j["findings"]
    if len(f) != 1: return None
    return f[0]["ref"]["source"]
a, b = one(d), one(e)
if a is None or b is None: print("NOT-ONE-FINDING"); sys.exit()
print("verdicts-differ" if a["reserves"] != b["reserves"] else "verdicts-SAME")
print("aligns-%s" % a["reserves"]); print("reserves-%s" % b["reserves"])
print("text-a-%s" % a["text"].split()[0]); print("text-b-%s" % b["text"].split()[0])
print("offset-%d-%d" % (a["stmt_offset"], b["stmt_offset"]))
print("cand-has-source" if d["findings"][0]["cand"]["source"] else "cand-source-MISSING")
# `reserves' and `chosen' are two different facts and the ALIGNS side shows it:
# no claimant of 000006 reserves, so the owner comes back with chosen
# "unreserved" -- which says the bytes belong to no statement at all, where
# reserves alone says only that THIS statement does not occupy them.
print("chosen-a-%s" % a["chosen"]); print("chosen-b-%s" % b["chosen"])
print("finding-on-the-finding" if "source" in d["findings"][0] else "source-is-per-side")
PY
swant() { if grep -qx "$1" "$T/s.out"; then pass "$2"; else fail "$2"; cat "$T/s.out"; fi; }
swant "verdicts-differ" "acceptance: the SAME finding at the SAME offset gets OPPOSITE verdicts"
swant "aligns-False"    "the DS 0F side reports reserves false -- it only aligned over the bytes"
swant "reserves-True"   "the DS CL2 side reports reserves true -- it occupied them"
swant "text-a-PAD"      "and the verdict comes with the card that produced it (PAD)"
swant "text-b-HOLD"     "and with HOLD on the other side, which is a different card"
swant "offset-6-6"      "both at 000006: the distinction is not a difference of position"
swant "cand-has-source" "both sides carry their own source -- two levels, two files"
swant "chosen-a-unreserved" "the ALIGNS side: nothing claiming 000006 reserves it, so chosen says so"
swant "chosen-b-reserving"  "the RESERVES side: a claimant does, and chosen names that rule"
swant "source-is-per-side"  "and source is NOT on the finding -- that is what /2 means"

# The insert case, where the two sides resolve to DIFFERENT cards of DIFFERENT
# files: the candidate's inserted instruction to its own card, and the
# reference's zero-length insertion point to the statement it goes BEFORE.
"$A" tests/align-a.s -o "$T/sa.obj" --stmts="$T/sa.tsv" >/dev/null 2>&1
"$A" tests/align-b.s -o "$T/sb.obj" --stmts="$T/sb.tsv" >/dev/null 2>&1
"$D" --align-diff "$T/sa.obj" "$T/sb.obj" --json "$T/sab.json" \
     --ref-stmts "$T/sa.tsv" --cand-stmts "$T/sb.tsv" -o /dev/null 2>/dev/null
python3 - "$T/sab.json" > "$T/sab.out" 2>&1 <<'PY'
import json, sys
j = json.load(open(sys.argv[1])); f = j["findings"][0]
r, c = f["ref"]["source"], f["cand"]["source"]
print("kind-%s" % f["kind"])
print("ref-op-%s" % r["text"].split()[0]); print("cand-op-%s" % c["text"].split()[0])
print("files-differ" if r["file"] != c["file"] else "files-SAME")
print("ref-len-%d" % f["ref"]["length"])
print("matches" if all(j["stmts"][s]["matches_object"] for s in ("ref","cand")) else "MISMATCH")
PY
awant() { if grep -qx "$1" "$T/sab.out"; then pass "$2"; else fail "$2"; cat "$T/sab.out"; fi; }
awant "kind-insert"  "the insert case is still an insert with the export attached"
awant "ref-len-0"    "and the reference side of it is a zero-length insertion POINT"
awant "ref-op-ST"    "which resolves to the statement the insertion goes before"
awant "cand-op-A"    "while the candidate's own card is the instruction that was added"
awant "files-differ" "the two cards are in two different files, which is the point"
awant "matches"      "and each export's extent agrees with its object's length"

# THE LAST CLAIMANT OF AN OFFSET IS NOT THE RULE -- the last that RESERVES is,
# and the difference was found in the control corpus rather than reasoned about.
# IEHPROG1's second section winds the counter back, overwrites six statements and
# winds it forward with a bare ORG whose advance is +10: that ORG CLAIMS
# 4476..4485 and is last in listing order, while the deck holds 50210000 92801000
# 0A14 -- the ST, the MVI and the SVC. An ORG moves over bytes and never writes
# them. 45 of 3,266 overlapped offsets over the 30 control CSECTs, in three
# modules, twice inside IEHPROG1 alone (mvs38src).
#
# align-g.s reproduces the shape: offset 000008 has THREE claimants, and the deck
# holds the middle one. NEGATIVE CONTROL against the rule this replaced, which is
# a real mutant and not an additive option: at 6a40fd0 the same document says
# chosen=last, text=ORG, reserves=false -- a repair told the ORG owns those bytes
# edits the ORG.
"$A" tests/align-g.s -o "$T/og.obj" --stmts="$T/og.tsv" >/dev/null 2>&1
"$A" tests/align-h.s -o "$T/oh.obj" --stmts="$T/oh.tsv" >/dev/null 2>&1
"$D" --align-diff "$T/og.obj" "$T/oh.obj" --json "$T/og.json" \
     --ref-stmts "$T/og.tsv" --cand-stmts "$T/oh.tsv" -o /dev/null 2>/dev/null
python3 - "$T/og.json" > "$T/og.out" 2>&1 <<'PY'
import json, sys
j = json.load(open(sys.argv[1]))
f = j["findings"]
if len(f) != 1: print("NOT-ONE-FINDING-%d" % len(f)); sys.exit()
s = f[0]["ref"]["source"]
print("offset-%d" % f[0]["ref"]["offset"])
print("claimants-%d" % s["claimants"])
print("chosen-%s" % s["chosen"])
print("op-%s" % s["text"].split()[1])
print("reserves-%s" % s["reserves"])
PY
owant() { if grep -qx "$1" "$T/og.out"; then pass "$2"; else fail "$2"; cat "$T/og.out"; fi; }
owant "offset-8"     "the ORG case lands at 000008, inside the range the bare ORG claims"
owant "claimants-3"  "three statements claim it: the first L, the MVI over it, and the ORG"
owant "chosen-reserving" "and the one taken is the last that RESERVES, not the last"
owant "op-MVI"       "which is the MVI -- what the deck holds at that offset"
owant "reserves-True" "so the verdict is that the bytes are OCCUPIED, not moved over"

# AN INSERTION POINT NEED NOT FALL ON A SOURCE BOUNDARY. A disassembly's
# boundaries are the DECODER's: in align-j.s the two bytes X'5800' and the first
# two of the DS after them decode together as one four-byte L 0,0(0,0), so the
# decoder's next boundary is 000008 while `BUF DS CL8' runs 000006..00000D. The
# deletion point lands two bytes INSIDE that card and the card has to be SPLIT.
#
# THE PROPERTY IS length == 0, NOT "inside", and three earlier attempts at this
# fixture failed by pinning "inside". Over the 832 (mvs38src): 170 encloses in 63
# modules, all length 0, while 2,168 findings of NON-zero length also start
# inside their chosen statement and are correctly reserving or unreserved. The
# separation is exact both ways, so a fixture keyed on "inside" would pass on any
# of those 2,168 and prove nothing.
"$A" tests/align-i.s -o "$T/ei.obj" --stmts="$T/ei.tsv" >/dev/null 2>&1
"$A" tests/align-j.s -o "$T/ej.obj" --stmts="$T/ej.tsv" >/dev/null 2>&1
"$D" --align-diff "$T/ei.obj" "$T/ej.obj" --json "$T/ei.json" \
     --ref-stmts "$T/ei.tsv" --cand-stmts "$T/ej.tsv" -o /dev/null 2>/dev/null
python3 - "$T/ei.json" > "$T/ei.out" 2>&1 <<'PY'
import json, sys
j = json.load(open(sys.argv[1]))
f = j["findings"]
if len(f) != 1: print("NOT-ONE-FINDING-%d" % len(f)); sys.exit()
c = f[0]["cand"]; s = c["source"]
print("kind-%s" % f[0]["kind"])
print("cand-len-%d" % c["length"])
print("chosen-%s" % s["chosen"])
print("inside" if s["stmt_offset"] < c["offset"] < s["stmt_offset"] + s["stmt_length"]
      else "NOT-INSIDE")
print("op-%s" % s["text"].split()[1])
print("ref-chosen-%s" % f[0]["ref"]["source"]["chosen"])
PY
ewant() { if grep -qx "$1" "$T/ei.out"; then pass "$2"; else fail "$2"; cat "$T/ei.out"; fi; }
ewant "kind-delete"      "the enclose case is a delete, which is where a zero length comes from"
ewant "cand-len-0"       "and its candidate side has length 0 -- an insertion POINT, not a range"
ewant "inside"           "that point is strictly inside the card the export gives for it"
ewant "chosen-encloses"  "so chosen says encloses: the card has to be SPLIT, not replaced"
ewant "op-DS"            "and the card is the DS the decoder ran past, not the statement at 000008"
ewant "ref-chosen-reserving" "while the reference side of the same finding is an ordinary owner"

# A STALE EXPORT IS THE MISTAKE NOTHING ELSE CAN SEE: it parses, the header is
# right, the section name matches and every offset looks plausible, because it
# belongs to a different build of the same source. The section's length is the
# one scalar both sides state independently. Truncating the export also leaves
# the finding's offset uncovered, which is the only way to reach
# `no-owning-statement' -- so both states are exercised by one run, and the third
# (`no-statement-export') by leaving the other side's flag off.
awk -F'\t' 'BEGIN{OFS="\t"} /^#/{print;next}
    {if(c==0){for(i=1;i<=NF;i++) if($i=="loc") c=i; print; next} if($c+0 < 6) print}' \
    "$T/sd.tsv" > "$T/strunc.tsv"
"$D" --align-diff "$T/sd.obj" "$T/sf.obj" --json "$T/stale.json" \
     --ref-stmts "$T/strunc.tsv" -o /dev/null 2>"$T/stale.err"
grep -q 'STALE export' "$T/stale.err" \
    && pass "an export whose extent disagrees with the object is reported, not swallowed" \
    || { fail "a stale export must be reported"; cat "$T/stale.err"; }
python3 - "$T/stale.json" > "$T/stale.out" 2>&1 <<'PY'
import json, sys
j = json.load(open(sys.argv[1])); f = j["findings"][0]
print("ref-%s" % (f["ref"].get("source_absent") or "present"))
print("cand-%s" % (f["cand"].get("source_absent") or "present"))
print("matches-%s" % j["stmts"]["ref"]["matches_object"])
print("cand-side-%s" % (j["stmts"]["cand"] is None))
PY
twant() { if grep -qx "$1" "$T/stale.out"; then pass "$2"; else fail "$2"; cat "$T/stale.out"; fi; }
twant "ref-no-owning-statement" "an offset no statement claims says so BY NAME, not with a bare null"
twant "cand-no-statement-export" "and a side with no export at all says a DIFFERENT thing"
twant "matches-False"           "matches_object is false where the extents disagree"
twant "cand-side-True"          "a side given no export is null in the document, not an empty object"

# ---- refusals, for the source half ----------------------------------------
"$D" --align-diff "$T/sd.obj" "$T/sf.obj" --stmts "$T/sd.tsv" -o /dev/null >/dev/null 2>"$T/r1.err"
[ $? = 16 ] && grep -q 'ref-stmts' "$T/r1.err" \
    && pass "--stmts is as370's option and the refusal names the two that are ours" \
    || { fail "--stmts must be refused BY NAME"; cat "$T/r1.err"; }
"$D" --align-diff "$T/sd.obj" "$T/sf.obj" --ref-stmts "$T/sd.tsv" -o /dev/null >/dev/null 2>"$T/r2.err"
[ $? = 16 ] \
    && pass "an export without --json is refused: nothing in the text report holds it" \
    || { fail "an export without --json must be refused"; cat "$T/r2.err"; }
"$D" --align-diff "$T/sd.obj" "$T/sf.obj" --json /dev/null --ref-stmts "$T/sa.tsv" \
     -o /dev/null >/dev/null 2>"$T/r3.err"
[ $? = 16 ] && grep -q 'ALIGNX' "$T/r3.err" \
    && pass "an export of the WRONG section is refused, and the refusal NAMES what it found" \
    || { fail "the refusal must name the sections the file does carry"; cat "$T/r3.err"; }
"$D" --align-diff "$T/sd.obj" "$T/sf.obj" --json /dev/null --ref-stmts /dev/null \
     -o /dev/null >/dev/null 2>"$T/r4.err"
[ $? = 16 ] && grep -q 'not an as370' "$T/r4.err" \
    && pass "a file that is not the export is refused on its first line" \
    || { fail "a non-export must be refused"; cat "$T/r4.err"; }

# ---- a section that is not the deck's first one (cc370#415) ---------------
# EVERY OTHER FIXTURE HERE IS A SINGLE SECTION AT ESD ADDRESS 0, which is the one
# address at which this defect cannot appear. A deck numbers every address it
# files under a section in the MODULE's space -- the TXT card's address, the
# RLD's P-position, the LD entry's address and the END card's entry point -- and
# load_section read all four as offsets into the section.
#
# AND THE ROUND TRIP CANNOT SEE IT. A section read eight bytes too far comes out
# as one `DS XLn' over zeros, and assembling that DS reproduces the same zeros:
# the deck matches, the suite passes, and 66 bytes of AHLMCMSG are gone. That is
# why the checks below are on the CONTENT and one of them is on the first section
# of the same deck, which is the null control.
#
# On the pre-change binary (main at 85d5278) this block fails in five places at
# once: `DS XL8 not covered by TXT' at 000000, ENT at 000008, the adcon at
# 000010, `A(SECTB+X''14'')' instead of a label in the section, and the last six
# bytes missing entirely.
"$A" tests/twosect.s -o "$T/ts.obj" > "$T/ts.asm" 2>&1
if [ $? -ge 8 ]; then fail "the two-section fixture does not assemble"; head -3 "$T/ts.asm"; fi
"$D" --csect SECTB "$T/ts.obj" -o "$T/ts-b.s" 2>"$T/ts-b.err"
"$D" --csect SECTA "$T/ts.obj" -o "$T/ts-a.s" 2>"$T/ts-a.err"
[ -s "$T/ts-b.err" ]     && { fail "a section at a non-zero ESD address warns: $(cat "$T/ts-b.err")"; }     || pass "a section at a non-zero ESD address reads without a warning"
grep -q 'not covered by TXT' "$T/ts-b.s"     && fail "SECTB's text is there: no byte of it may read as uncovered"     || pass "a non-first section's TXT lands at its own offset 0, not at its origin"
grep -qE '^ENT +BALR +12,0 +000000' "$T/ts-b.s"     && pass "an LD entry's address is module-absolute too: ENT is at 000000"     || { fail "ENT must be at 000000"; grep -n 'BALR' "$T/ts-b.s"; }
grep -qE "^ +DC +A\(L00000C\)" "$T/ts-b.s"     && pass "an adcon's own-section target resolves inside the section, so it is a label"     || { fail "the adcon must resolve to a label in the section"; grep -n ' DC  *A' "$T/ts-b.s"; }
grep -qE '^ +END +ENT' "$T/ts-b.s"     && pass "the END card's entry point is module-absolute too, and lands on ENT"     || { fail "END must name ENT"; grep -n 'END' "$T/ts-b.s"; }
grep -q "X'CCDD99999999'" "$T/ts-b.s"     && pass "the bytes past the adcon survive -- the section is read to its end"     || { fail "the tail of the section is missing"; cat "$T/ts-b.s"; }
# THE NULL CONTROL, on the same deck: SECTA is at address 0 and must not move.
grep -q "X'AABBCC'" "$T/ts-a.s" && ! grep -q 'not covered by TXT' "$T/ts-a.s"     && pass "the first section of the same deck is unchanged -- the null control"     || { fail "the first section moved; the fix reached where it must not"; cat "$T/ts-a.s"; }
# THE ROUND TRIP ON SECTB, which proves the bytes and not only the spelling --
# and it cannot be a plain comparison, for the reason the fixture exists. The
# disassembly is one CSECT, so reassembling it puts SECTB at origin 0, and an
# own-section adcon's assembled value is its target's MODULE address: X'14' in
# the original, X'0C' alone. So the test is the stronger statement rather than a
# masked one -- every byte outside the RLD must be equal, and every word inside
# it must differ by EXACTLY the section's origin.
"$A" "$T/ts-b.s" -o "$T/ts-b.obj" > "$T/ts-b.asm" 2>&1
if [ $? -ge 8 ]; then
    fail "SECTB's disassembly does not assemble"; head -3 "$T/ts-b.asm"
elif python3 -c "
import sys

def read(path):
    d = open(path, 'rb').read()
    sid = org = None
    img = bytearray(64); rlds = []
    for o in range(0, len(d)-79, 80):
        c = d[o:o+80]
        if c[:4] == bytes((0x02,0xC5,0xE2,0xC4)):
            first = int.from_bytes(c[14:16],'big'); n = int.from_bytes(c[10:12],'big')
            for k in range(n//16):
                e = c[16+k*16:32+k*16]
                if e[8] in (0,4) and e[:8].decode('cp037').rstrip() == 'SECTB':
                    sid = first + k; org = int.from_bytes(e[9:12],'big')
    for o in range(0, len(d)-79, 80):
        c = d[o:o+80]
        if c[:4] == bytes((0x02,0xE3,0xE7,0xE3)) and int.from_bytes(c[14:16],'big') == sid:
            a = int.from_bytes(c[5:8],'big') - org; n = int.from_bytes(c[10:12],'big')
            img[a:a+n] = c[16:16+n]
        if c[:4] == bytes((0x02,0xD9,0xD3,0xC4)):
            n = int.from_bytes(c[10:12],'big'); b = c[16:16+n]; i = 0; r = p_ = None
            while i + 4 <= len(b):
                if r is None or not cont:
                    r = int.from_bytes(b[i:i+2],'big'); p_ = int.from_bytes(b[i+2:i+4],'big'); i += 4
                fl = b[i]; ad = int.from_bytes(b[i+1:i+4],'big'); i += 4
                cont = fl & 1
                ln = ((fl >> 2) & 3) + 1
                if p_ == sid and r == sid: rlds.append((ad - org, ln))
    return org, bytes(img[:18]), sorted(rlds)

o1, t1, r1 = read('$T/ts.obj')
o2, t2, r2 = read('$T/ts-b.obj')
if r1 != r2:
    print('  the RLD moved: %s against %s' % (r1, r2)); sys.exit(1)
if not r1:
    print('  no own-section RLD item: this test proves nothing'); sys.exit(1)
bad = []
mask = bytearray(b'\\x01' * 18)
for a, ln in r1:
    v1 = int.from_bytes(t1[a:a+ln],'big'); v2 = int.from_bytes(t2[a:a+ln],'big')
    if v1 - v2 != o1 - o2:
        bad.append('adcon at %d: %X against %X, difference %d, origins %d and %d'
                   % (a, v1, v2, v1-v2, o1, o2))
    for k in range(a, a+ln): mask[k] = 0
for i in range(18):
    if mask[i] and t1[i] != t2[i]: bad.append('byte %d: %02X against %02X' % (i, t1[i], t2[i]))
if bad:
    for m in bad: print('  ' + m)
    sys.exit(1)
"; then
    pass "round trip: every byte outside the RLD is identical and every adcon differs by exactly the origin"
else
    fail "round trip: SECTB's bytes differ where they must not"
fi

# ---- --isa, a narrower opcode table (cc370#395) ---------------------------
# THE ROUND TRIP CANNOT SEE A FALSE INSTRUCTION: it re-encodes the wrong reading
# to the same bytes, so `ADR 3,4' over two bytes of data and a real ADR are
# equally byte-safe. Narrowing the table is the only mechanism that removes the
# reading, and the only thing that may not move is the deck.
#
# The cut is 236 mnemonics to 128 -- floating point 52, privileged 30, packed
# decimal 16, I/O 10 -- and the class column lives in opc_table.h where both
# tools read it, gated by as370/tests/opcinv.c (which also asserts the counts and
# re-runs the whole inversion assertion UNDER the cut).
"$A" tests/isa.s -o "$T/isa.obj" > "$T/isa.asm" 2>&1
if [ $? -ge 8 ]; then fail "the --isa fixture does not assemble"; head -3 "$T/isa.asm"; fi
"$D" --isa full "$T/isa.obj" -o "$T/isa-full.s" 2>/dev/null
"$D" --isa app  "$T/isa.obj" -o "$T/isa-app.s"  2>/dev/null
"$D" --isa s370 "$T/isa.obj" -o "$T/isa-s370.s" 2>/dev/null
"$D"            "$T/isa.obj" -o "$T/isa-def.s"  2>/dev/null

grep -q 'ADR' "$T/isa-full.s" && grep -q 'ZAP' "$T/isa-full.s" \
    && pass "--isa full reads two bytes of data as ADR and eight as ZAP" \
    || { fail "the fixture must produce a false decode under full or it proves nothing"
         cat "$T/isa-full.s"; }
grep -q 'ADR' "$T/isa-app.s" || grep -q 'ZAP' "$T/isa-app.s" \
    && { fail "--isa app must decode neither -- ADR is floating point, ZAP decimal"
         cat "$T/isa-app.s"; } \
    || pass "--isa app decodes neither: the false readings are gone"
grep -q "DC    X'F811000000000000'" "$T/isa-app.s" \
    && pass "and the data comes back as the EIGHT bytes the source wrote" \
    || { fail "under app the run must be the source's own eight bytes"
         grep "DC" "$T/isa-app.s"; }
# THE HALF THAT MATTERS MORE: nothing real is lost. A cut that removed a true
# instruction would be a cut that changed the reading of code, not of data.
isamiss=0
for ins in 'BALR  12,0' 'LR    1,2' 'LR    3,4' 'BR    14'; do
    grep -q "$ins" "$T/isa-app.s" || { echo "  missing under app: $ins"; isamiss=1; }
    grep -q "$ins" "$T/isa-full.s" || { echo "  missing under full: $ins"; isamiss=1; }
done
[ $isamiss = 0 ] && pass "every real instruction survives the cut -- both LRs, the BALR and the BR" \
                 || { fail "the cut lost a real instruction"; }
# AND THE DECK DOES NOT MOVE. This is the property the whole option rests on: a
# wrong cut changes how a byte PRINTS, not what anything DOES.
for isa in full app; do
    "$A" "$T/isa-$isa.s" -o "$T/isa-$isa.obj" > "$T/isa-$isa.asm" 2>&1
    n=$(( ($(wc -c < "$T/isa.obj") / 80 - 1) * 80 ))
    head -c $n "$T/isa.obj"        > "$T/isa-$isa.a.cut"
    head -c $n "$T/isa-$isa.obj"   > "$T/isa-$isa.b.cut"
    cmp -s "$T/isa-$isa.a.cut" "$T/isa-$isa.b.cut" \
        && pass "round trip under --isa $isa: the deck reassembles byte-identically" \
        || { fail "round trip under --isa $isa: the deck moved"
             cmp "$T/isa-$isa.a.cut" "$T/isa-$isa.b.cut" | head -2; }
done
cmp -s "$T/isa-s370.s" "$T/isa-def.s" \
    && pass "--isa s370 IS the default: this table is the System/370 set" \
    || fail "--isa s370 must be byte-identical to no --isa at all"
"$D" --isa s360 "$T/isa.obj" -o /dev/null >/dev/null 2>"$T/isa-s360.err"
[ $? = 16 ] && grep -q '17,885' "$T/isa-s360.err" \
    && pass "--isa s360 is refused, and the refusal carries what it would cost" \
    || { fail "--isa s360 must be refused WITH the measurement"; cat "$T/isa-s360.err"; }

# ---- refusals -------------------------------------------------------------
"$D" --csect NOSUCHCS "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 2 ] && pass "an unknown --csect exits 2, not 0" || fail "an unknown --csect exits 2, not 0"
"$D" --isa nonsense "$T/a.obj" -o /dev/null >/dev/null 2>&1
[ $? = 16 ] && pass "an --isa value that is not one of the four is refused" \
             || fail "an --isa value that is not one of the four is refused"

[ $fails = 0 ] && echo "dasm370: all checks passed" || echo "dasm370: $fails FAILURE(S)"
exit $fails
