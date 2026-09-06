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

if [ ! -f "$FIX/BLSUZZ2R.obj" ]; then
    echo "SKIP: fixtures ($FIX not present; set CMPLMD_FIXTURES)"
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

    # --- --difout must produce a file that closes its own comparison --------
    $C --difout "$TMP/rt.difin" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1
    if $C --difin "$TMP/rt.difin" "$DD/IGG0CLB3.obj" "$DD/IGG0CLB3.dlib" >/dev/null 2>&1; then
        pass "--difout round-trips: its own output closes the comparison"
    else
        fail "--difout: the file it wrote does not close the comparison"
    fi
else
    echo "SKIP: 102-pair cases (no $FIX/dlib-102)"
fi

echo
echo "$fails failure(s)"
exit $fails
