#!/bin/sh
# file370 -- the CESD listing (cc370, mvs38src ask 1).
#
# THE CHANGE EXISTS BECAUSE OF AN ASYMMETRY, so the control is the half that was
# already right: file370 -v has always dumped an OBJECT DECK's ESD and never a
# BOUND MEMBER's CESD -- the same question, answered for one container only.
# Test 3 fails on the pre-change binary; test 4 must keep passing, or the fix
# was a rewrite rather than a completion.
cd "$(dirname "$0")/../.." || exit 2
F=./file370/file370
FIX="${FILE370_FIXTURES:-../mvs38src/work/measurements}"
pass=0; fail=0
pass() { echo "PASS: $1"; pass=$((pass+1)); }
fail() { echo "FAIL: $1"; fail=$((fail+1)); }
[ -x "$F" ] || { echo "no binary"; exit 2; }

LM="$FIX/target-bytes/tk5/LPALIB/IKJEFT01.bin"
DECK="$FIX/ifox-run/decks/IKJEES20.obj"
if [ ! -f "$LM" ] || [ ! -f "$DECK" ]; then
    echo "SKIP: no fixtures at $FIX (set FILE370_FIXTURES)"
    exit 0
fi

# --- 1. a bound member's CESD is listed at all ------------------------------
n=$("$F" --csects "$LM" | grep -c '^    CESD')
if [ "$n" -lt 30 ]; then fail "--csects listed $n CESD entries for IKJEFT01, expected 36"
else pass "--csects lists a bound member's CESD ($n entries)"
fi

# --- 2. the three SECTIONS are named, with origin and length ----------------
ok=1
for pair in "1:IKJEFT01" "2:IKJEFT06" "33:IKJEFTSC"; do
    id=${pair%%:*}; nm=${pair##*:}
    "$F" --csects "$LM" | grep -qE "^    CESD +$id  $nm +SD +addr=[0-9A-F]{6}  len=[0-9A-F]{6}" || { ok=0; echo "  missing $id $nm"; }
done
[ "$ok" -eq 1 ] && pass "the sections carry name, type, origin and length" \
                || fail "a section line is missing or malformed"

# --- 3. THE COMPOSITE TYPES, which an object deck cannot carry --------------
# Before this change esd_type() had no case for them and answered "??" -- so a
# reader saw the entry and not what it was.  LR is what an LD becomes when
# bound; Nul is a deleted entry whose name survives.
o=$("$F" --csects "$LM")
if ! printf '%s\n' "$o" | grep -q ' LR  '; then fail "no LR entry decoded (an LD, once bound)"
elif ! printf '%s\n' "$o" | grep -q ' Nul '; then fail "no Nul entry decoded (a deleted entry)"
elif printf '%s\n' "$o" | grep -q ' ??  '; then
    fail "an entry decoded to '??': $(printf '%s\n' "$o" | grep ' ??  ' | head -1)"
else pass "LR and Nul are named, and nothing decodes to '??'"
fi

# --- 4. -v on a bound member now lists the CESD (THE ASYMMETRY) -------------
if [ "$("$F" -v "$LM" | grep -c '^    CESD')" -lt 30 ]; then
    fail "-v on a bound member still does not list the CESD"
else
    pass "-v lists a bound member's CESD, as it has always done for a deck"
fi

# --- 5. CONTROL: the deck path is unchanged ---------------------------------
if [ "$("$F" -v "$DECK" | grep -c '^    ESD')" -lt 2 ]; then
    fail "-v no longer lists an object deck's ESD -- the half that was right"
else
    pass "-v still lists an object deck's ESD (unchanged)"
fi

# --- 6. --json parses and carries the fields --------------------------------
if command -v python3 >/dev/null; then
    if "$F" --csects --json "$LM" 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
c=d["csects"]
assert d["count"]==len(c), (d["count"], len(c))
s=[e for e in c if e["type"]=="SD"]
assert [e["esdid"] for e in s]==[1,2,33], s
assert s[0]["name"]=="IKJEFT01" and "addr" in s[0] and "len" in s[0]
assert any(e["type"]=="LR" and "owner" in e for e in c)
' 2>/dev/null; then
        pass "--json parses; count agrees, sections and an LR owner carry their fields"
    else
        fail "--json: invalid, or a field is missing"
    fi
fi

# --- 7. THE CONSUMER'S QUESTION, which is why this exists -------------------
# "Can two distributions' copies of a CSECT be linked interchangeably?" is
# answered by comparing the two symbol lists.  IKJEFT06 is a standalone DLIB
# element on MVS/CE and section 2 inside TK5's IKJEFT01.
CE=$(find "$FIX/dlib" -name 'IKJEFT06.dlib' 2>/dev/null | head -1)
if [ -n "$CE" ]; then
    "$F" --csects "$CE" | awk '$4=="SD"||$4=="LR"{print $3}' | sort > /tmp/_f370ce.$$
    "$F" --csects "$LM" | awk '$3=="IKJEFT06"{print $3} $4=="LR" && /owner=2/{print $3}' | sort > /tmp/_f370tk.$$
    nce=$(wc -l < /tmp/_f370ce.$$ | tr -d ' ')
    if [ "$nce" -ne 27 ]; then fail "IKJEFT06 on MVS/CE: expected 27 symbols, got $nce"
    elif ! cmp -s /tmp/_f370ce.$$ /tmp/_f370tk.$$; then
        fail "IKJEFT06's symbol lists differ between the distributions"
        diff /tmp/_f370ce.$$ /tmp/_f370tk.$$ | head -4
    else
        pass "IKJEFT06 exports the same 27 symbols on MVS/CE and TK5 (interchangeable)"
    fi
    rm -f /tmp/_f370ce.$$ /tmp/_f370tk.$$
fi

echo
echo "$fail failure(s)"
[ "$fail" -eq 0 ]
