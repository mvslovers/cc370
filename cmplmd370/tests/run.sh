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

echo
echo "$fails failure(s)"
exit $fails
