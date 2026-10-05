#!/bin/sh
# idrdump370 -- cc370#429.
#
# THE ACCEPTANCE HAS TWO HALVES AND THE SECOND IS THE ONE THAT MATTERS:
# a module known to carry a ZAP must report the entry's section, AND a module
# known to carry none must report none.  Without the second, a parser that finds
# something everywhere passes -- which is exactly how a loose scan for X'80'
# looks successful: over IEFVFA it reads the two genuine IDRs and then reports
# subtypes X'14', X'58' and X'C8', which are TEXT records.
#
# Fixtures live in mvs38src; skip rather than fail when they are absent.
cd "$(dirname "$0")/../.." || exit 2
I=./idrdump370/idrdump370
FIX="${IDRDUMP_FIXTURES:-../mvs38src/work/measurements}"
pass=0; fail=0
pass() { echo "PASS: $1"; pass=$((pass+1)); }
fail() { echo "FAIL: $1"; fail=$((fail+1)); }

[ -x "$I" ] || { echo "no binary"; exit 2; }
"$I" --version >/dev/null || { echo "--version failed"; exit 2; }

if [ ! -d "$FIX/dlib" ]; then
    echo "SKIP: no fixtures at $FIX (set IDRDUMP_FIXTURES)"
    exit 0
fi

find_m() { find "$FIX/dlib" -name "$1.dlib" 2>/dev/null | head -1; }

# --- 1. a ZAP is reported, with the section its CESDID NAMES ---------------
f=$(find_m IEFVFA)
if [ -n "$f" ]; then
    o=$("$I" "$f" 2>&1)
    if ! printf '%s' "$o" | grep -q 'HMASPZAP  csect=IEFVFA .*cesdid=2 .*zap=#DYN004'; then
        fail "IEFVFA: expected csect=IEFVFA cesdid=2 zap=#DYN004"; echo "$o"
    else
        pass "a ZAP entry reports its section, CESDID and identifier"
    fi
fi

# --- 2. AND THE SECTION IS NOT THE MEMBER NAME ------------------------------
# IGC018's zap sits on IEC0SCR1, a different CSECT inside the same member.
# This is the case a count of entries cannot answer and the reason the CESDID
# is decoded at all: "the member carries a zap" is not "this CSECT was serviced".
f=$(find_m IGC018)
if [ -n "$f" ]; then
    o=$("$I" "$f" 2>&1)
    if ! printf '%s' "$o" | grep -q 'HMASPZAP  csect=IEC0SCR1 .*cesdid=6'; then
        fail "IGC018: the zap names IEC0SCR1, not the member"; echo "$o"
    else
        pass "a zap on a non-first CSECT names that CSECT, not the member"
    fi
fi

# --- 3. THE NEGATIVE HALF ---------------------------------------------------
# 5,248 of the 5,252 DLIB members carry no SPZAP entry at all.  A parser that
# finds one anywhere fails here and nowhere else.
nz=0; n=0
for f in $(find "$FIX/dlib" -name '*.dlib' | head -60); do
    n=$((n+1))
    case "$("$I" "$f" 2>&1)" in *"HMASPZAP  csect="*) nz=$((nz+1));; esac
done
if [ "$nz" -ne 0 ]; then
    fail "$nz of $n unzapped members reported a ZAP entry"
else
    pass "$n members with no ZAP report none (the half that catches a finder-of-everything)"
fi

# --- 4. the chain, not a scan ----------------------------------------------
# IEFVFA has exactly four IDRs and ends on LASTIDR.  A loose X'80' scan reports
# more, with subtypes that are text records.
f=$(find_m IEFVFA)
if [ -n "$f" ]; then
    o=$("$I" "$f" 2>&1)
    nrec=$(printf '%s\n' "$o" | grep -c '^  @')
    nlast=$(printf '%s\n' "$o" | grep -c '\[LAST\]')
    nun=$(printf '%s\n' "$o" | grep -c 'unknown')
    if [ "$nrec" -ne 4 ]; then fail "IEFVFA: expected 4 IDR records, got $nrec"; echo "$o"
    elif [ "$nlast" -lt 1 ]; then fail "IEFVFA: no record marked LASTIDR -- the chain has no end"
    elif [ "$nun" -ne 0 ]; then fail "IEFVFA: $nun records decoded to an unknown subtype"
    else pass "the chain is walked and ends on LASTIDR: 4 records, no unknown subtype"
    fi
fi

# --- 5. LKED is always present ---------------------------------------------
miss=0; n=0
for f in $(find "$FIX/dlib" -name '*.dlib' | head -40); do
    n=$((n+1))
    case "$("$I" "$f" 2>&1)" in *LKED*) ;; *) miss=$((miss+1));; esac
done
if [ "$miss" -ne 0 ]; then fail "LKED IDR missing from $miss of $n members; the spec says always"
else pass "the always-present LKED IDR is found in $n of $n"
fi

# --- 6. --csect filters to one section --------------------------------------
f=$(find_m IGC018)
if [ -n "$f" ]; then
    a=$("$I" --csect IEC0SCR1 "$f" 2>&1 | grep -c 'HMASPZAP')
    b=$("$I" --csect IGC018   "$f" 2>&1 | grep -c 'HMASPZAP')
    if [ "$a" -ne 1 ] || [ "$b" -ne 0 ]; then
        fail "--csect: IEC0SCR1 gave $a (want 1), IGC018 gave $b (want 0)"
    else
        pass "--csect reports the named section and is silent on the other"
    fi
fi

# --- 6b. X'08' names its section too, and IS the applied-service signal ------
# IKJEFT01 carries three APARs and ZERO zap entries, so a zap-only reader calls
# it unserviced.  The three CESDIDs must resolve to the three sections the
# member is bound from -- confirmed independently by mvs38src reading one id out
# of each DLIB element separately.
T="${IDRDUMP_TARGET:-$FIX/target-bytes/tk5}"
if [ -f "$T/LPALIB/IKJEFT01.bin" ]; then
    o=$("$I" "$T/LPALIB/IKJEFT01.bin" 2>&1)
    ok=1
    for pair in "IKJEFT01:UY13431" "IKJEFT06:UZ42826" "IKJEFTSC:UY43678"; do
        c=${pair%%:*}; a=${pair##*:}
        printf '%s\n' "$o" | grep -q "user      csect=$c .*id=$a" || { ok=0; echo "  missing $c -> $a"; }
    done
    nz=$(printf '%s\n' "$o" | grep -c 'HMASPZAP  csect=')
    if [ "$ok" -ne 1 ]; then fail "IKJEFT01: the three APARs are not on their sections"; echo "$o"
    elif [ "$nz" -ne 0 ]; then fail "IKJEFT01 should carry NO zap entries, got $nz"
    else pass "X'08' puts three APARs on three sections, with zero zap entries"
    fi
fi

# --- 6c. the negative half again, for X'08' ---------------------------------
f=$(find_m IEFVFA)
if [ -n "$f" ]; then
    # service entries only: the translator record is shown under --csect too (#809)
    n=$("$I" --csect NOSUCHSECT "$f" 2>&1 | grep -E '(HMASPZAP|user) ' | grep -c 'csect=')
    if [ "$n" -ne 0 ]; then fail "--csect NOSUCHSECT reported $n entries"
    else pass "--csect naming no real section reports nothing (neither subtype)"
    fi
fi

# --- 7. --json is valid and carries the CESDID ------------------------------
f=$(find_m IEFVFA)
if [ -n "$f" ] && command -v python3 >/dev/null; then
    if "$I" --json "$f" 2>/dev/null | python3 -c '
import json,sys
d=json.load(sys.stdin)
z=[r for r in d["idr"] if r["subtype"]=="HMASPZAP"]
assert d["records"]==4, d["records"]
assert d["malformed"] is False
assert z and z[0]["cesdid"]==2 and z[0]["csect"]=="IEFVFA", z
' 2>/dev/null; then
        pass "--json parses, and carries the CESDID and the section"
    else
        fail "--json: invalid or missing the decoded fields"
    fi
fi

# --- #809: the LKED and translator records decoded; empty SPZAP; --csect; format
# An IEWL-linked member from ld370's fixtures: SPZAP (no entries), LKED
# 5752SC104 V03 M08 26170 04:54:27, translator 5741SC103 V02 M01 26170 for E2E.
E2E=ld370/tests/fixtures/e2e.iewl-member.bin
out=$("$I" "$E2E")
case "$out" in
    *"LKED      5752SC104 V03 M08  date=26170  time=045427"*) pass "LKED record decoded (program, version, date, time)" ;;
    *) fail "LKED not decoded: $out" ;;
esac
case "$out" in
    *"translator 5741SC103 V02 M01  date=26170  csect=E2E"*) pass "translator record decoded and attributed" ;;
    *) fail "translator not decoded: $out" ;;
esac
if "$I" --json "$E2E" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d["idr"])==d["records"]==3 and d["idr"][0]["entries"]==0 else 1)'; then
    pass "--json lists the empty SPZAP record, so idr and records agree"
else fail "--json idr/records disagree"; fi
"$I" --csect E2E "$E2E" | grep -q 'LKED' && pass "--csect keeps the linkage-editor record" || fail "--csect hid the LKED record"
printf 'just text\n' > "/tmp/idr809.$$"
"$I" "/tmp/idr809.$$" >/dev/null 2>"/tmp/idr809e.$$"; r=$?
[ $r = 2 ] && grep -q 'not a load module' "/tmp/idr809e.$$" && pass "a text file is a format error, rc 2" || fail "text file: rc $r"
rm -f "/tmp/idr809.$$" "/tmp/idr809e.$$"

echo
echo "$fail failure(s)"
[ "$fail" -eq 0 ]
