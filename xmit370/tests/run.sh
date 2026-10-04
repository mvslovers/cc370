#!/bin/sh
# xmit370 test suite.  Run from the repo root:  sh xmit370/tests/run.sh
# Exit status = number of failed cases.
#
# The load-bearing test is the ORACLE one: a real TSO TRANSMIT of a source PDS,
# which is what pinned every field this tool computes.  It lives outside the
# repo (see ORACLE below) and the case skips itself when it is absent, the way
# the as370 corpus check skips without a libc370 checkout.

set -u
cd "$(dirname "$0")/../.." || exit 99

TMP="${TMPDIR:-/tmp}/xmit370-tests.$$"
mkdir -p "$TMP" || exit 99
trap 'rm -rf "$TMP"' EXIT

CHECK=xmit370/tests/xmit_check.py
ORACLE="${XMIT370_ORACLE:-$HOME/Downloads/mvs-tk5/ctca_demo/sysgen/ctca_demo.xmi}"
CBT="${XMIT370_CBT:-../cbt571/PDS}"

fails=0
pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; fails=$((fails + 1)); }

echo "=== building ==="
cc -O2 -Wall -Wextra -Werror -Icommon/include \
   -o xmit370/xmit370 xmit370/src/xmit370.c common/src/mvs370.c common/src/obj370.c || exit 99
X=./xmit370/xmit370

# ---------------------------------------------------------------- fixtures
mkdir -p "$TMP/src"
cat > "$TMP/src/hello" <<'EOF'
//HELLO   JOB  (ACCT),'SAMPLE',CLASS=A,MSGCLASS=X
//STEP1   EXEC PGM=IEFBR14
EOF
cat > "$TMP/src/readme" <<'EOF'
This is a sample member.

It has a blank line above and trailing blanks below.
EOF
printf 'no trailing newline' > "$TMP/src/nonl"
: > "$TMP/src/empty"
# An empty member has no data blocks at all, so its directory TTR points straight
# at its DL=0 end-of-member record.  EBCDIC sorts E < H < J < N < R, so `empty`
# lands first and `jempty` lands in the MIDDLE -- the case that actually exercises
# a zero-block member sharing a track with the members on either side.
: > "$TMP/src/jempty"

# ------------------------------------------------------- 1. basic create
if $X create -o "$TMP/a.xmit" --dsn IBMUSER.SAMPLIB --stats-date 2026-01-02T03:04:05 \
       "$TMP/src" >/dev/null 2>&1 &&
   python3 "$CHECK" "$TMP/a.xmit" --members 5 >/dev/null; then
    pass "create: 5 members, default FB/80/3120"
else
    fail "create: 5 members, default FB/80/3120"
    python3 "$CHECK" "$TMP/a.xmit" --members 5
fi

# --------------------------------------------- 2. reproducible output
$X create -o "$TMP/a2.xmit" --dsn IBMUSER.SAMPLIB --stats-date 2026-01-02T03:04:05 \
   "$TMP/src" >/dev/null 2>&1
if cmp -s "$TMP/a.xmit" "$TMP/a2.xmit"; then
    pass "create: --stats-date makes the output byte-reproducible"
else
    fail "create: --stats-date makes the output byte-reproducible"
fi

# ------------------------------------------------------ 3. round trip
mkdir -p "$TMP/out"
$X extract -C "$TMP/out" "$TMP/a.xmit" >/dev/null 2>&1
rt=0
for f in EMPTY HELLO JEMPTY NONL README; do
    [ -f "$TMP/out/$f" ] || { rt=1; echo "  missing $f"; }
done
# Trailing blanks are the pad character and do not survive, so compare against
# the input with trailing blanks stripped.  README carries a blank line in the
# middle: that record is all pad blanks and must come back as an empty line, not
# be dropped.
for f in hello readme; do
    u=$(echo "$f" | tr '[:lower:]' '[:upper:]')
    sed -e 's/[[:space:]]*$//' "$TMP/src/$f"  > "$TMP/$f.want"
    sed -e 's/[[:space:]]*$//' "$TMP/out/$u"  > "$TMP/$f.got" 2>/dev/null
    cmp -s "$TMP/$f.want" "$TMP/$f.got" || { rt=1; echo "  $u differs"; }
done
[ "$(cat "$TMP/out/NONL" 2>/dev/null)" = "no trailing newline" ] || { rt=1; echo "  NONL differs"; }
for f in EMPTY JEMPTY; do
    [ -f "$TMP/out/$f" ] && [ ! -s "$TMP/out/$f" ] || { rt=1; echo "  $f is not empty"; }
done
[ $rt -eq 0 ] && pass "extract: round trip (incl. empty member between two others)" \
             || fail "extract: round trip"

# ------------------------------------------- 4. --no-stats directory shape
if $X create -o "$TMP/ns.xmit" --dsn IBMUSER.SAMPLIB --no-stats "$TMP/src" >/dev/null 2>&1 &&
   python3 "$CHECK" "$TMP/ns.xmit" --members 5 --no-stats >/dev/null; then
    pass "create: --no-stats emits 12-byte directory entries (C=00)"
else
    fail "create: --no-stats emits 12-byte directory entries (C=00)"
fi

# ------------------------------------- 5. track density at a small blocksize
# 800-byte blocks (10 records) put many records on a track; this is the regime
# that produced the S106-0F over-packing bug, so the checker must see it stay
# legal.  BLKSIZE must be a multiple of LRECL for RECFM=FB, hence 800 not 1024.
if $X create -o "$TMP/b800.xmit" --dsn IBMUSER.SAMPLIB --blocksize 800 "$TMP/src" >/dev/null 2>&1 &&
   python3 "$CHECK" "$TMP/b800.xmit" --blocksize 800 --members 5 >/dev/null; then
    pass "create: --blocksize 800 keeps track packing physically valid"
else
    fail "create: --blocksize 800 keeps track packing physically valid"
fi

# ------------------------------------------------- 6. negative controls
neg() {   # neg DESCRIPTION FILE [extra args...]
    desc=$1; shift
    if $X create -o "$TMP/neg.xmit" --dsn IBMUSER.T "$@" >"$TMP/neg.log" 2>&1; then
        fail "reject: $desc (exited 0)"
    else
        pass "reject: $desc"
    fi
}
mkdir -p "$TMP/bad"
awk 'BEGIN{ s=""; for(i=0;i<90;i++) s=s "X"; print s }' > "$TMP/bad/toolong"
neg "line longer than LRECL" "$TMP/bad"
rm -f "$TMP/bad/toolong"

printf 'comment with an em dash \342\200\224 here\n' > "$TMP/bad/utf8"
neg "UTF-8 input" "$TMP/bad"
rm -f "$TMP/bad/utf8"

printf 'binary\000\001\002data\n' > "$TMP/bad/binary"
neg "control characters (binary content)" "$TMP/bad"
rm -f "$TMP/bad/binary"

: > "$TMP/bad/9digit"
neg "member name starting with a digit" "$TMP/bad"
rm -f "$TMP/bad/9digit"

neg "blocksize not a multiple of lrecl" "$TMP/src" --blocksize 3121
neg "blocksize over the device block maximum" "$TMP/src" --blocksize 20000

# --------------------------------------------------- 7. the ORACLE case
# A real TSO TRANSMIT of JUERGEN.CTCA.PDS (PO, FB, LRECL=80, BLKSIZE=19040,
# 7 members, 3380).  Every DCB field, the ISPF statistics layout and the
# directory split were read off this file.
if [ -f "$ORACLE" ]; then
    o="$($X list "$ORACLE" 2>&1)"
    ok=1
    echo "$o" | grep -q "DSORG=PO RECFM=FB LRECL=80 BLKSIZE=19040" || { ok=0; echo "  DCB mismatch"; }
    echo "$o" | grep -q "7 member(s)"                              || { ok=0; echo "  member count"; }
    echo "$o" | grep -q '\$README .* 4000 bytes .* 50 lines JUERGEN' || { ok=0; echo "  \$README stats"; }
    echo "$o" | grep -q 'CTCASOS .*215040 bytes .*2688 lines MADNICK' || { ok=0; echo "  CTCASOS stats"; }
    [ $ok -eq 1 ] && pass "oracle: real TSO TRANSMIT decodes exactly" \
                  || fail "oracle: real TSO TRANSMIT decodes exactly"

    # every member's byte count must be lines*80 -- the end-to-end proof that
    # the TTR walk lands on the right records
    if $X list "$ORACLE" | awk '/TTR=/ { if ($3 != $8 * 80) bad=1 } END { exit bad+0 }'; then
        pass "oracle: every member is exactly lines*80 bytes"
    else
        fail "oracle: every member is exactly lines*80 bytes"
    fi
else
    echo "SKIP: oracle ($ORACLE not present; set XMIT370_ORACLE)"
fi

# ------------------------------------- 8. large real corpus round trip
# 217 members, 37 directory blocks, names with $ @ #.
if [ -d "$CBT" ]; then
    if $X create -o "$TMP/cbt.xmit" --dsn CBT.FILE571.PDS --stats-date 2008-04-09 \
           --latin1 --exclude '*.xmi' --exclude 'OBJECT' --exclude 'LICENSE' \
           "$CBT" >/dev/null 2>&1; then
        mkdir -p "$TMP/cbtx"
        $X extract -C "$TMP/cbtx" "$TMP/cbt.xmit" >/dev/null 2>&1
        bad=0
        for f in "$TMP/cbtx"/*; do
            b=$(basename "$f")
            cmp -s "$f" "$CBT/$b" || { bad=$((bad + 1)); }
        done
        n=$(ls "$TMP/cbtx" | wc -l | tr -d ' ')
        if [ "$bad" -eq 0 ] && python3 "$CHECK" "$TMP/cbt.xmit" --members 217 >/dev/null; then
            pass "corpus: $n members round trip byte-identically (37 directory blocks)"
        else
            fail "corpus: $bad member(s) differ after round trip"
        fi
    else
        fail "corpus: create failed"
    fi
else
    echo "SKIP: corpus ($CBT not present; set XMIT370_CBT)"
fi

# ---------------------------------------------------- physical CKD geometry
# xmit_check.py above asserts track DENSITY but not the UDEBX data extent, and
# the extent is what makes a directory TTR resolve to the right absolute track.
# ld370's track_check.py asserts both, plus that every env-header byte the
# emitter does not stamp still equals the committed template -- and since the
# 3350 constants and that template are the SAME in both tools, the check belongs
# in one place rather than two.  It reads an XMIT directly with --from-xmit.
#
# The multi-cylinder case is the one that matters here: with a single cylinder
# the correct UDEBX end/NMTRK happen to equal the template's own defaults, so a
# wrong offset or a dropped stamp is invisible.
echo "=== geometry: 3350 density, R numbering, UDEBX extent, env template ==="
GEO=ld370/tests/track_check.py
mkdir -p "$TMP/geo"
i=1
while [ "$i" -le 40 ]; do
    awk -v n="$i" 'BEGIN{for(k=0;k<400;k++) printf "MEMBER %03d LINE %05d PADDING PADDING\n", n, k}' \
        > "$TMP/geo/GM$i"
    i=$((i + 1))
done
geo_fails=0
if $X create -o "$TMP/geo.xmit" --dsn IBMUSER.GEO.ASM \
        --stats-date 2026-01-02T03:04:05 "$TMP/geo" >/dev/null 2>&1 \
   && $X create -o "$TMP/geo132.xmit" --dsn IBMUSER.GEOB.ASM --lrecl 132 --blocksize 3168 \
        --stats-date 2026-01-02T03:04:05 "$TMP/src" >/dev/null 2>&1 \
   && $X create -o "$TMP/geof.xmit" --dsn IBMUSER.GEOC.ASM --recfm f --blocksize 80 \
        --stats-date 2026-01-02T03:04:05 "$TMP/src" >/dev/null 2>&1; then
    python3 "$GEO" --from-xmit --pack-cap --recfm FB \
        "$TMP/geo.xmit" "$TMP/geo132.xmit" "$TMP/a.xmit" || geo_fails=1
    python3 "$GEO" --from-xmit --pack-cap --recfm F "$TMP/geof.xmit" || geo_fails=1
    # A single small source PDS must stay on ONE track: pin it, so ld370's
    # one-block-per-track policy leaking in here is visible.  It leaves every
    # geometry rule satisfied and merely spreads the image over more tracks.
    python3 "$GEO" --from-xmit --pack-cap --recfm FB --max-tracks 1 "$TMP/a.xmit" \
        || geo_fails=1

    # STRADDLE fixture.  The packing budget is 19069 while a 3350 physically
    # holds 19254, and most block sizes cannot tell the two apart -- at 3120 a
    # track takes 5 records either way.  At --blocksize 2560 a record costs 2745
    # and SIX fit under 19069 while SEVEN fit under 19254, so this is where
    # "correcting" the budget up to the real track length becomes visible.  It
    # needs long runs of FULL blocks: a member's last block is short and its
    # DL=0 EOF costs another record, both of which blur the boundary, so the
    # members are 960 lines = 30 whole blocks each.
    mkdir -p "$TMP/dense"
    di=1
    while [ "$di" -le 3 ]; do
        awk -v n="$di" 'BEGIN{for(k=0;k<960;k++) printf "DENSE %03d LINE %05d %s\n", n, k, \
            "PADDING PADDING PADDING PADDING PADDIN"}' > "$TMP/dense/BM$di"
        di=$((di + 1))
    done
    if $X create -o "$TMP/dense.xmit" --dsn IBMUSER.DENSE.ASM --blocksize 2560 \
            --stats-date 2026-01-02T03:04:05 "$TMP/dense" >/dev/null 2>&1; then
        python3 "$GEO" --from-xmit --pack-cap --recfm FB "$TMP/dense.xmit" || geo_fails=1
    else
        fail "geometry: dense straddle fixture did not build"
    fi
    if [ "$geo_fails" -eq 0 ]; then
        pass "geometry: multi-cylinder + FB/F shapes within 3350 limits, extent spans the data"
    else
        fail "geometry: see the FAIL lines above"
    fi
else
    fail "geometry: fixture create failed"
fi

# ---------------------------------------------------------------- #804
# The Command Reference findings; each check fails on 1.2.0.
echo "=== #804: names, values, options, non-XMIT input, --latin1 ==="
D4="$TMP/d804"; mkdir -p "$D4/one" "$D4/long" "$D4/utf"
printf 'LINE\n' > "$D4/one/a.txt"
x4() {   # NAME WANT-RC PATTERN ARGS...
    nm=$1; want=$2; pat=$3; shift 3
    "$X" "$@" >"$TMP/x4.out" 2>"$TMP/x4.err"; r=$?
    if [ "$r" = "$want" ] && { [ -z "$pat" ] || grep -qE -e "$pat" "$TMP/x4.err" "$TMP/x4.out"; }; then pass "$nm (rc $r)"
    else fail "$nm: rc $r (want $want), $(head -1 "$TMP/x4.err")"; fi
}
printf 'x\n' > "$D4/long/verylongname.txt"
x4 "a 12-character derived name is refused, not cut" 1 "'VERYLONGNAME' is not a valid member name" create -o "$D4/l.xmit" --dsn A.B "$D4/long"
x4 "--member lower is upper-cased" 0 "" create -o "$D4/m.xmit" --dsn A.B --member lower="$D4/one/a.txt" "$D4/long" --exclude 'verylong*'
"$X" list "$D4/m.xmit" | grep -qE '^ +LOWER ' && pass "the member is LOWER in the directory" || fail "--member lower not upper-cased"
x4 "--userid longer than 8 is refused" 2 "--userid 'abcdefghij' is 10 characters" create -o "$D4/u.xmit" --dsn A.B --userid abcdefghij "$D4/one"
x4 "--userid is upper-cased" 0 "" create -o "$D4/u.xmit" --dsn A.B --userid tester --stats-date 2026-10-04 "$D4/one"
"$X" list "$D4/u.xmit" | grep -q ' TESTER' && pass "the statistics say TESTER" || fail "--userid not upper-cased"
x4 "--recfm f with --blocksize 3120 is refused" 2 "--recfm f is unblocked" create --recfm f --blocksize 3120 -o "$D4/f.xmit" --dsn A.B "$D4/one"
x4 "--recfm f alone takes BLKSIZE = LRECL" 0 "" create --recfm f -o "$D4/f.xmit" --dsn A.B "$D4/one"
x4 "--stats-date 2026-13-45 is refused" 2 "is not a date" create --stats-date 2026-13-45 -o "$D4/s.xmit" --dsn A.B "$D4/one"
x4 "--stats-date T25:00:00 is refused" 2 "is not a date" create --stats-date 2026-10-04T25:00:00 -o "$D4/s.xmit" --dsn A.B "$D4/one"
x4 "--tabs abc is refused" 2 "--tabs takes a number, not 'abc'" create --tabs abc -o "$D4/t.xmit" --dsn A.B "$D4/one"
x4 "list on a text file says why" 1 "not a TSO transmission" list "$D4/one/a.txt"
x4 "extract on a text file says why" 1 "not a TSO transmission" extract -C "$D4" "$D4/one/a.txt"
printf 'caf\303\251\n' > "$D4/utf/u.txt"
x4 "--latin1 on a UTF-8 file warns" 0 "the file is UTF-8, and --latin1" create --latin1 -o "$D4/x.xmit" --dsn A.B "$D4/utf"
x4 "-C on create is refused" 2 "-C does not apply to 'create'" create -C "$D4" -o "$D4/c.xmit" --dsn A.B "$D4/one"
x4 "--dsn on list is refused" 2 "--dsn does not apply to 'list'" list --dsn A.B "$D4/u.xmit"
x4 "--version after the command" 0 "xmit370 " list "$D4/u.xmit" --version
x4 "--help after the command" 0 "-V, --version" create --help
"$X" list "$D4/u.xmit" | grep -qE "INMRECFM +VBS, transmission records \(X'0001'\)" \
    && pass "list names INMR03's INMRECFM" || fail "INMR03 INMRECFM: $("$X" list "$D4/u.xmit" | grep INMRECFM | tr '\n' '|')"

echo
echo "$fails failure(s)"
exit $fails
