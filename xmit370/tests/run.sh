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
   -o xmit370/xmit370 xmit370/src/xmit370.c common/src/mvs370.c || exit 99
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

echo
echo "$fails failure(s)"
exit $fails
