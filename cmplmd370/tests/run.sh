#!/bin/sh
# cmplmd370 regression.
#
# The tool's load-bearing property is "exit 0 ONLY on identity", and a
# comparator's failure mode is not inventing differences -- it is returning 0 too
# easily.  Every case below therefore checks that a difference IS detected;
# the identical cases exist to prove the tool is not simply always red.
cd "$(dirname "$0")/../.." || exit 99
C=./cmplmd370/cmplmd370
FIX="${CMPLMD_FIXTURES:-../mvs38src/work/fixtures}"
TMP="${TMPDIR:-/tmp}/cmplmd370-tests.$$"
mkdir -p "$TMP" || exit 99
trap 'rm -rf "$TMP"' EXIT

fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails + 1)); }

cc -O2 -Wall -Wextra -Werror -Icommon/include \
   -o cmplmd370/cmplmd370 cmplmd370/src/cmplmd370.c common/src/*.c || exit 99

# --- record-reader cases, on members we build ourselves -----------------
# These need no corpus: mkmember.py assembles each member from the layout in
# docs/load-module-format.md, so the cases run everywhere and nothing
# proprietary is committed.  Each one stood for a real refusal or a real
# silent error before #372.
MK=cmplmd370/tests/mkmember.py
for k in overlay segmap trailing sym flagtype truncated rldorder; do
    python3 "$MK" "$k" "$TMP/$k.bin" || exit 99
done
python3 "$MK" deck:ROOT:11:0x40    "$TMP/ROOT.obj"    || exit 99
python3 "$MK" deck:SEGA:AA:0x20    "$TMP/SEGA.obj"    || exit 99
python3 "$MK" deck:SEGB:BB:0x20    "$TMP/SEGB.obj"    || exit 99
python3 "$MK" deck:ONESECT:5A:0x20 "$TMP/ONESECT.obj" || exit 99
python3 "$MK" deck:WITHSYM:7E:0x20 "$TMP/WITHSYM.obj" || exit 99
python3 "$MK" deck:SEG3:33:0x20    "$TMP/SEG3.obj"    || exit 99
python3 "$MK" deck:SEG4:44:0x20    "$TMP/SEG4.obj"    || exit 99
python3 "$MK" deck:FLAGGED:3C:0x20 "$TMP/FLAGGED.obj" || exit 99
python3 "$MK" rldorderdeck         "$TMP/RLDORDER.obj" || exit 99

# THE ORDER OF THE TWO LISTS IN A CONTROL RECORD.  A record carrying both an
# ID/length list and RLD info holds the RLD FIRST; every other record has one or
# the other, and in those the two orders produce the same bytes -- so no member
# anyone had looked at could tell them apart.  Reading the list first began the
# RLD parse four bytes late and desynchronised the record, and here that costs
# the one item: the relocated fullword at X'10' goes unmasked, and the member's
# resolved address then reads as an ordinary text difference against the deck's
# zero addend.  Measured over 13,102 members: 2,489 records carry both lists and
# 2,489 of them put the list after the RLD.
if $C --csect RLDORDER "$TMP/RLDORDER.obj" "$TMP/rldorder.bin" >/dev/null 2>&1
then pass "a relocated field is masked when its record carries BOTH lists"
else fail "a relocated field is masked when its record carries BOTH lists"
fi

# An SD whose type byte kept an edit-time control bit (X'20').  Testing the
# whole byte made the section invisible: "no section named FLAGGED", exit 2.
# 21 of TK5's 2,396 bound target members carry these, IEANUC01's entire
# nucleus among them.
if $C --csect FLAGGED "$TMP/FLAGGED.obj" "$TMP/flagtype.bin" >/dev/null 2>&1
then pass "CESD type byte X'20' over an SD is still a section"
else fail "CESD type byte X'20' over an SD is still a section"
fi

# Overlay: ROOT in segment 1, SEGA and SEGB BOTH at 0x40 in segments 2 and 3.
# One flat image is last-writer-wins, so SEGA used to be compared against
# SEGB's text -- silently, with an ordinary verdict.  All three must match.
for sc in ROOT SEGA SEGB; do
    if $C --csect $sc "$TMP/$sc.obj" "$TMP/overlay.bin" >/dev/null 2>&1
    then pass "overlay: $sc sliced from its OWN segment"
    else fail "overlay: $sc sliced from its OWN segment"
    fi
done

# The segment MAPPING, which `overlay' above cannot prove -- it is built on the
# same assumption it would be testing.  There, CESD order, segment order and
# section count all coincide, so "CESDSEG n", "the n-th section" and "the n-th
# group that owns a section" are the same function.  HEWLF064, TK5's only
# overlay member, does not separate them either: its 24 SD entries ARE in
# ascending segment order and all 7 of its segments own at least one section.
#
# segmap makes them disagree.  CESD order is SEG3(seg 3), ROOT(seg 1), a null
# entry, SEG4(seg 4); the text groups are 1: ROOT, 2: nobody's, 3: SEG3,
# 4: SEG4.  Scored against two mutants of load_lmod, built for this and not
# committed -- A maps the i-th section to segment i, B maps the k-th distinct
# CESDSEG to the k-th group:
#
#                      overlay              segmap
#   current            ROOT SEGA SEGB pass  ROOT SEG3 SEG4 pass
#   mutant A           PASSES all three     fails all three
#   mutant B           PASSES all three     fails SEG3 and SEG4
#   pre-#372 (flat)    fails SEGA           fails SEG3
#
# So `overlay' guards the flat image and nothing else, and this guards the rule
# the slicing rests on: CESDSEG n is the n-th SEGEND-delimited text group,
# counting groups and not sections.
for sc in ROOT SEG3 SEG4; do
    if $C --csect $sc "$TMP/$sc.obj" "$TMP/segmap.bin" >/dev/null 2>&1
    then pass "segmap: $sc keyed on CESDSEG, not on CESD position"
    else fail "segmap: $sc keyed on CESDSEG, not on CESD position"
    fi
done

# A module linked with TEST leads with its SYM records, not its CESD.  The
# walk used to end at -1 there and the CESD was never reached.
if $C --csect WITHSYM "$TMP/WITHSYM.obj" "$TMP/sym.bin" >/dev/null 2>&1
then pass "SYM records ahead of the CESD do not end the walk"
else fail "SYM records ahead of the CESD do not end the walk"
fi

# Bytes after MODEND: the module ends at MODEND, so this is a reportable
# anomaly and NOT a reason to refuse a verdict.  One TK5 member has 28 of them
# and all 22 of its CSECTs were "malformed load-module record stream".
if $C --csect ONESECT "$TMP/ONESECT.obj" "$TMP/trailing.bin" >/dev/null 2>&1
then pass "bytes after MODEND still yield a verdict"
else fail "bytes after MODEND still yield a verdict"
fi
if $C --json --csect ONESECT "$TMP/ONESECT.obj" "$TMP/trailing.bin" 2>/dev/null \
     | grep -q '"trailing_bytes": 28' &&
   $C --json --csect ONESECT "$TMP/ONESECT.obj" "$TMP/trailing.bin" 2>/dev/null \
     | grep -q '"anomalies": "trailing-bytes"'
then pass "--json names the anomaly and counts the trailing bytes"
else fail "--json names the anomaly and counts the trailing bytes"
fi
if $C --json --csect ONESECT "$TMP/ONESECT.obj" "$TMP/trailing.bin" 2>/dev/null \
     | grep -q '"image_incomplete": false'
then pass "trailing bytes do not make the image incomplete"
else fail "trailing bytes do not make the image incomplete"
fi

# An image the reader could not finish must not yield a verdict by default:
# the bytes that ARE there may match, and that is not the same as a match.
python3 "$MK" deck:CHOPPED:99:0x20 "$TMP/CHOPPED.obj" || exit 99
$C --csect CHOPPED "$TMP/CHOPPED.obj" "$TMP/truncated.bin" >/dev/null 2>&1
if [ $? -eq 2 ]; then pass "an incomplete image is refused, not compared"
else fail "an incomplete image is refused, not compared"; fi
if $C --json --csect CHOPPED "$TMP/CHOPPED.obj" "$TMP/truncated.bin" 2>/dev/null \
     | grep -q '"image_incomplete": true'
then pass "--json says WHY it was refused"
else fail "--json says WHY it was refused"
fi
$C --allow-incomplete --csect CHOPPED "$TMP/CHOPPED.obj" "$TMP/truncated.bin" >/dev/null 2>&1
if [ $? -ne 2 ]; then pass "--allow-incomplete compares it anyway"
else fail "--allow-incomplete compares it anyway"; fi

if [ ! -f "$FIX/BLSUZZ2R.obj" ]; then
    echo "SKIP: corpus fixtures ($FIX not present; set CMPLMD_FIXTURES)"
    echo ""
    echo "$fails failure(s)"
    [ "$fails" -eq 0 ] || exit 1
    exit 0
fi

# --- identity, against a REAL shipped DLIB load module -------------------
# Neither member carries an RLD item, so --clearrld masks nothing here and the
# verdict is an unmasked byte-for-byte match of the whole section.
for m in BLSUZZ2R IGG026DU; do
    if $C "$FIX/$m.obj" "$FIX/$m.dlib" >/dev/null 2>&1; then
        pass "$m: as370 deck == shipped DLIB load module"
    else
        fail "$m: expected identity"
    fi
done

# --- a real, measured difference must be reported, not smoothed over -----
# IEFJDSNA differs in exactly ONE byte of 211, at 0x00AA.  That is the
# sensitivity the tool exists for: same length, no adcons, one byte.
if $C "$FIX/IEFJDSNA.obj" "$FIX/IEFJDSNA.dlib" >"$TMP/j.log" 2>&1; then
    fail "IEFJDSNA: reported identity, but one byte differs at 0x00AA"
elif grep -q "1 byte(s) differ in 1 cluster" "$TMP/j.log"; then
    pass "IEFJDSNA: the single differing byte is found"
else
    fail "IEFJDSNA: differs, but not as one 1-byte cluster: $(tail -2 "$TMP/j.log" | head -1)"
fi

# --- TEETH: a flipped text byte must not survive either mode -------------
# Including --clearrld, whose whole job is to blank bytes: if it blanked one
# byte too many the tool would go quietly green on a changed instruction.
python3 - "$FIX/BLSUZZ2R.obj" "$TMP/bad.obj" <<'PY'
import sys
d = bytearray(open(sys.argv[1], 'rb').read())
TXT = bytes((0x02, 0xE3, 0xE7, 0xE3))
for off in range(0, len(d) - 79, 80):
    if d[off:off+4] == TXT:
        d[off+16] ^= 0x01
        break
open(sys.argv[2], 'wb').write(d)
PY
for mode in "" "--no-clearrld"; do
    # shellcheck disable=SC2086
    if $C $mode "$TMP/bad.obj" "$FIX/BLSUZZ2R.dlib" >/dev/null 2>&1; then
        fail "flipped text byte went undetected with '${mode:-default}'"
    else
        pass "flipped text byte detected with '${mode:-default}'"
    fi
done

# --- a name that is not there is an ERROR, never a silent 0 --------------
$C --csect NOSUCHCS "$FIX/BLSUZZ2R.obj" "$FIX/BLSUZZ2R.dlib" >/dev/null 2>&1
case $? in
    2) pass "--csect with an unknown name exits 2, not 0" ;;
    0) fail "--csect with an unknown name exited 0" ;;
    *) fail "--csect with an unknown name exited $?, expected 2" ;;
esac

# --- the gap classification, which decides "recovered" from "not" -------
# A differing byte no TXT card covers is one as370 never wrote: the loader
# zeroed it and the shipped module's content there is DS-hole residue.  A
# difference INSIDE generated text is a real disagreement.  The tool computes
# that itself rather than leaving it to a reader, and these two cases were
# established independently from the assembler listings.
if [ -f "$FIX/dlib-102/IEFJDSNA.obj" ]; then
    DD="$FIX/dlib-102"
    $C "$DD/IEFJDSNA.obj" "$DD/IEFJDSNA.dlib" > "$TMP/g1.log" 2>&1
    grep -q "ALL in DS holes" "$TMP/g1.log" \
        && pass "IEFJDSNA: the one differing byte is classified as a DS hole" \
        || fail "IEFJDSNA: not classified as a hole: $(sed -n 2p "$TMP/g1.log")"
    $C "$DD/HMASMRCC.obj" "$DD/HMASMRCC.dlib" > "$TMP/g2.log" 2>&1
    grep -q "all in GENERATED TEXT" "$TMP/g2.log" \
        && pass "HMASMRCC: differs inside generated text, so a real divergence" \
        || fail "HMASMRCC: not classified as generated text: $(sed -n 2p "$TMP/g2.log")"

    # --- --difin, TWO-SIDED ------------------------------------------------
    # The only option whose purpose is to SUPPRESS differences, so it is checked
    # in both directions: with the file each module must pass, and WITHOUT it
    # each must still fail.  A one-sided check would pass a --difin that masks
    # everything, which is precisely how a comparator goes quietly green.
    if [ -f "$FIX/holes.difin" ]; then
        n_ok=0; n_bad=0
        for m in AMDSAGTF IEFDB4FA IEFJDSNA IFDMSG53 IGG0CLB3 IGG0CLBR ISTINCR1 ISTZBFAM ISTZGFAB; do
            $C --difin "$FIX/holes.difin" "$DD/$m.obj" "$DD/$m.dlib" >/dev/null 2>&1; w=$?
            $C "$DD/$m.obj" "$DD/$m.dlib" >/dev/null 2>&1; wo=$?
            if [ $w -eq 0 ] && [ $wo -ne 0 ]; then n_ok=$((n_ok + 1)); else n_bad=$((n_bad + 1)); fi
        done
        [ $n_bad -eq 0 ] && pass "--difin: 9 modules pass with it and fail without it" \
                         || fail "--difin: $n_bad of 9 wrong (ok=$n_ok)"

        # ...and it must not reach past what it lists.
        if $C --difin "$FIX/holes.difin" "$DD/HMASMRCC.obj" "$DD/HMASMRCC.dlib" >/dev/null 2>&1; then
            fail "--difin masked HMASMRCC, which it does not list"
        else
            pass "--difin does not mask a module it does not list"
        fi
    else
        echo "SKIP: --difin (no $FIX/holes.difin)"
    fi

    # --- --json: valid, complete, and agreeing with the exit code ----------
    # The caller is about to run this over thousands of pairs and read the JSON
    # rather than the text, so the three ways it could quietly lie are checked:
    # invalid output, a verdict that disagrees with the exit status, and a
    # cluster list that is short.
    cp cmplmd370/tests/json_check.py "$TMP/jcheck.py" 2>/dev/null
    $C --json "$DD/IKTCAS54.obj" "$DD/IKTCAS54.dlib" > "$TMP/j.json" 2>&1
    jrc=$?
    if python3 "$TMP/jcheck.py" "$TMP/j.json" "$jrc" 2>"$TMP/jerr"; then
        pass "--json: valid, complete, agrees with the exit code"
    else
        fail "--json: $(head -1 "$TMP/jerr")"
    fi

    # --- the JSON shape must not change on the ERROR paths -----------------
    $C --json --csect NOSUCHCS "$DD/IEFJDSNA.obj" "$DD/IEFJDSNA.dlib" > "$TMP/e.json" 2>&1
    erc=$?
    if python3 "$TMP/jcheck.py" "$TMP/e.json" "$erc" 2>"$TMP/eerr"; then
        pass "--json keeps its shape on an error path (exit=$erc)"
    else
        fail "--json error path: $(head -1 "$TMP/eerr")"
    fi

    # --- --difout must not truncate ---------------------------------------
    # IKTCAS54 differs in 319 clusters.  The fixed 64-cluster array this started
    # with silently dropped every range past the 64th, so the file it wrote did
    # not close its own comparison -- and nothing said so.
    $C --difout "$TMP/big.difin" "$DD/IKTCAS54.obj" "$DD/IKTCAS54.dlib" >/dev/null 2>&1
    nrange=$(grep -c '^[0-9A-F]' "$TMP/big.difin" 2>/dev/null || echo 0)
    if [ "$nrange" -lt 300 ]; then
        fail "--difout wrote only $nrange ranges for a 319-cluster difference"
    elif $C --difin "$TMP/big.difin" "$DD/IKTCAS54.obj" "$DD/IKTCAS54.dlib" >/dev/null 2>&1; then
        pass "--difout does not truncate: $nrange ranges close a 319-cluster difference"
    else
        fail "--difout: $nrange ranges written but the comparison stays open"
    fi

    # --- --difout must produce a file that closes its own comparison --------
    $C --difout "$TMP/rt.difin" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1
    if $C --difin "$TMP/rt.difin" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1; then
        pass "--difout round-trips: its own output closes the comparison"
    else
        fail "--difout: the file it wrote does not close the comparison"
    fi

    # --- #110: --difout must CARRY --difin FORWARD --------------------------
    # "so a reviewed run can seed the next one" is the deliverable's own wording,
    # and it did the opposite: write_difout emitted only the clusters it FOUND,
    # and --difin's ranges are by construction not among them.  So every pass
    # shrank the file.  Measured on AMDSAGTF before the fix:
    #
    #   --difout acc                       9 ranges, 82 bytes
    #   --difin acc --difout acc           acc EMPTY, rc 0
    #   --difin acc --difout next          next EMPTY -- so not an aliasing bug
    #   review 1 of 8, --difout part2      7 ranges, the REVIEWED one dropped
    #
    # The last is the sharp one: the file loses exactly what a human just
    # approved, and the run that does it exits 0.
    $C --difout "$TMP/acc" "$DD/AMDSAGTF.obj" "$DD/AMDSAGTF.dlib" >/dev/null 2>&1
    cp "$TMP/acc" "$TMP/acc.0"
    $C --difin "$TMP/acc" --difout "$TMP/acc" "$DD/AMDSAGTF.obj" "$DD/AMDSAGTF.dlib" >/dev/null 2>&1
    if ! cmp -s "$TMP/acc.0" "$TMP/acc"; then
        fail "--difout does not carry --difin forward: $(wc -l < "$TMP/acc.0") ranges in, $(wc -l < "$TMP/acc") out"
    elif ! $C --difin "$TMP/acc" "$DD/AMDSAGTF.obj" "$DD/AMDSAGTF.dlib" >/dev/null 2>&1; then
        fail "--difout: the carried file no longer closes the comparison"
    else
        pass "--difin acc --difout acc is idempotent on a converged comparison"
    fi

    # A PARTIAL review must survive: suppress one of the eight, and the file that
    # comes back must be IDENTICAL to the unreviewed run -- 7 found plus 1 masked
    # is the same set of 8.  Asserting the set rather than a count, because the
    # first version of this test asserted 9 and 9 was the LINE count: one header
    # plus eight ranges.
    printf '>AMDSAGTF\n0002A808\n' > "$TMP/part"
    $C --difin "$TMP/part" --difout "$TMP/part2" "$DD/AMDSAGTF.obj" "$DD/AMDSAGTF.dlib" >/dev/null 2>&1
    if ! grep -q '0002A808' "$TMP/part2" 2>/dev/null; then
        fail "--difout dropped the range --difin had suppressed (a reviewed decision)"
    elif ! cmp -s "$TMP/acc.0" "$TMP/part2"; then
        fail "--difout after a partial review differs from the unreviewed run:
$(diff "$TMP/acc.0" "$TMP/part2" | head -6)"
    else
        pass "--difout after a 1-of-8 review is identical to the unreviewed run"
    fi

    # What the run could not JUDGE is carried verbatim rather than pruned.
    # --csect naming a section that is not there compares nothing at all, so
    # before the fix --difout wrote an empty file and the whole review was gone.
    # Seeded from acc.0, the PRISTINE copy, never from acc: on a binary without
    # the fix the step above leaves acc empty, and empty-against-empty made this
    # check pass for the wrong reason -- a non-test that looked like a pass.
    $C --csect NOSUCH --difin "$TMP/acc.0" --difout "$TMP/cs" "$DD/AMDSAGTF.obj" "$DD/AMDSAGTF.dlib" >/dev/null 2>&1
    if ! cmp -s "$TMP/acc.0" "$TMP/cs"; then
        fail "--csect discarded the --difin ranges it never looked at"
    else
        pass "--difout carries forward what the run did not judge (--csect)"
    fi

    # THE CONTROL, and it is what makes this option B rather than a blind union:
    # a listed range that masks NOTHING is not carried.  IGG0CLB3's own difout
    # closes its comparison, so adding a bogus range to it leaves that range with
    # nothing to suppress, and the next file must come back WITHOUT it.
    $C --difout "$TMP/cl" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1
    cp "$TMP/cl" "$TMP/cl.bogus"; printf 'FFFFF001\n' >> "$TMP/cl.bogus"
    $C --difin "$TMP/cl.bogus" --difout "$TMP/cl.out" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1
    if grep -q 'FFFFF001' "$TMP/cl.out" 2>/dev/null; then
        fail "--difout carried a range that masked nothing (blind union, not B)"
    elif ! cmp -s "$TMP/cl" "$TMP/cl.out"; then
        fail "--difout: pruning the dead range also changed the live ones"
    else
        pass "--difout prunes a listed range that masks nothing, keeping the rest"
    fi
else
    echo "SKIP: 102-pair cases (no $FIX/dlib-102)"
fi

echo
echo "$fails failure(s)"
exit $fails
