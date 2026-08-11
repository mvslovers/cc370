#!/bin/sh
# cc370 host-side codegen regression tests.
#
# Uses the driver-private cc1 built by `make compiler` (build/gcc/cc1); override
# with CC1=/path/to/cc1.  Each case compiles a small C snippet to i370 HLASM and
# checks a property of the emitted assembler (no MVS required).
cd "$(dirname "$0")" || exit 2
ROOT=../..
CC1=${CC1:-$ROOT/build/gcc/cc1}
if [ ! -x "$CC1" ]; then
    echo "cc1 not found at $CC1 -- run 'make compiler' first (or set CC1=)" >&2
    exit 2
fi
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cc370test.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' 0
fail=0

# Compile $2 (a C file) with the extra flags in $3; capture diagnostics to
# $WORK/diag.  Returns the compiler exit status.
compile () { $CC1 -quiet -std=c89 $3 "$2" -o "$WORK/$1.s" >"$WORK/diag" 2>&1; }

# --- issue #17: external symbols collide silently when identifiers share a ---
# long prefix.  MVS/370 externals are limited to 8 characters; distinct C
# identifiers that truncate to the same name used to link to one another with
# no diagnostic.  cc370 must now warn.  An explicit __asm__ name (the issue's
# workaround) is emitted verbatim and must NOT warn.

# (1) two functions whose names truncate to the same 8-char symbol -> warn.
cat > "$WORK/fn.c" <<'EOF'
void codec_stream_encode(int x);
void codec_stream_decode(int x);
void codec_stream_encode(int x) { codec_stream_decode(x); }
void codec_stream_decode(int x) { codec_stream_encode(x); }
EOF
compile fn "$WORK/fn.c"
if grep -q "collides with" "$WORK/diag" && grep -q "CODEC@ST" "$WORK/diag"; then
    echo "collide-fn: OK (warned, both map to CODEC@ST)"
else
    echo "collide-fn: FAIL (no collision warning for codec_stream_encode/decode)"; fail=1
fi

# (2) two common (uninitialized) globals colliding -> warn (the other ESD path).
cat > "$WORK/cm.c" <<'EOF'
int codec_stream_state;
int codec_stream_stats;
EOF
compile cm "$WORK/cm.c"
if grep -q "collides with" "$WORK/diag"; then
    echo "collide-common: OK (warned)"
else
    echo "collide-common: FAIL (no warning for two colliding common globals)"; fail=1
fi

# (3) distinct 8-char prefixes must NOT warn (no false positive).
cat > "$WORK/ok.c" <<'EOF'
void codec_stream_encode(int x);
void codec_block_decode(int x);
void codec_stream_encode(int x) { codec_block_decode(x); }
void codec_block_decode(int x) { codec_stream_encode(x); }
EOF
compile ok "$WORK/ok.c"
if grep -q "collides with" "$WORK/diag"; then
    echo "distinct: FAIL (false positive on CODEC@ST vs CODEC@BL)"; fail=1
else
    echo "distinct: OK (no false positive)"
fi

# (4) the __asm__ workaround: two 8-char linkage names that differ are distinct
# object-deck symbols -> must NOT warn (no false positive on the workaround).
cat > "$WORK/asm.c" <<'EOF'
extern int cfg_p __asm__("FTPCFGDP");
extern int cfg_f __asm__("FTPCFGDF");
int cfg_p = 1;
int cfg_f = 2;
EOF
compile asm "$WORK/asm.c"
if grep -q "collides with" "$WORK/diag"; then
    echo "asm-name: FAIL (false positive on distinct 8-char __asm__ names)"; fail=1
else
    echo "asm-name: OK (distinct 8-char asm names)"
fi

# (5) __asm__ names LONGER than 8 chars that share their first 8: as370
# truncates the external symbol to 8 silently (diverging from Assembler XF,
# which diagnoses an over-length symbol), so PREFIXAB1 and PREFIXAB2 both
# become PREFIXAB. cc370 models as370 and must warn -- the workaround does not
# save a name that is itself too long.
cat > "$WORK/asmlong.c" <<'EOF'
extern int p __asm__("PREFIXAB1");
extern int f __asm__("PREFIXAB2");
int p = 1;
int f = 2;
EOF
compile asmlong "$WORK/asmlong.c"
if grep -q "collides with" "$WORK/diag" && grep -q "PREFIXAB" "$WORK/diag"; then
    echo "asm-long: OK (warned, both truncate to PREFIXAB)"
else
    echo "asm-long: FAIL (>8-char asm names truncating to PREFIXAB not caught)"; fail=1
fi

# (6) -Werror must promote the collision to a hard error (nonzero exit).
compile fnw "$WORK/fn.c" -Werror
if [ $? -ne 0 ]; then
    echo "werror: OK (collision is an error under -Werror)"
else
    echo "werror: FAIL (collision did not fail the build under -Werror)"; fail=1
fi

# --- issue #40: a 64-bit load through a dying pointer used to clobber its ---
# own base register: `L 2,0(2)` / `L 3,4+0(2)` -- the second load indexes off
# the loaded VALUE, a wild address on a 24-bit machine (S0C4 on MVS).  The
# fix loads the word the address still needs last.

# Scanner for the broken pair: `L d,disp(b)` with d==b immediately followed
# by `L d+1,4+disp(b)`.  (A lone self-clobbering L is ordinary pointer
# chasing and correct; only the pair is the defect.)
scan_pair () {
    awk '
    /^\* Function .* code/ { fn=$3 }
    { if (match($0, /^ +L +[0-9]+,[0-9]+\([0-9]+\)$/)) {
        split($0,a,/[ ,()]+/); d1=a[3];p1=a[4];b1=a[5]; prev=1; next }
      if (prev && match($0, /^ +L +[0-9]+,4\+[0-9]+\([0-9]+\)$/)) {
        split($0,c,/[ ,()+]+/); d2=c[3];p2=c[5];b2=c[6]
        if (d1==b1 && d2==d1+1 && b2==b1 && p2==p1) print fn }
      prev=0 }' "$1"
}

# (1) positive control: the scanner must flag a canned bad sequence --
# otherwise "no hits" below would also be the output of a broken scanner.
cat > "$WORK/canned.s" <<'EOF'
* Function bad code
         L     2,0(11)
         L     2,0(2)
         L     3,4+0(2)
EOF
if [ -n "$(scan_pair "$WORK/canned.s")" ]; then
    echo "pair-scanner: OK (flags the known-bad sequence)"
else
    echo "pair-scanner: FAIL (scanner does not detect the defect pattern)"; fail=1
fi

# (2) the issue's reproducer plus the correct-by-contrast variants: none may
# contain the broken pair.
cat > "$WORK/di.c" <<'EOF'
struct s { char pad[16]; unsigned long long v; int tail; };
unsigned f(const unsigned long long *p) { return (unsigned)(*p >> 32); }
unsigned a_dead(const struct s *p) { return (unsigned)(p->v >> 32); }
unsigned b_live(const struct s *p) { return (unsigned)(p->v >> 32)
                                          + (unsigned)p->tail; }
unsigned e_low (const struct s *p) { return (unsigned)p->v; }
int      d_cmp (const struct s *p, unsigned long long t) { return p->v < t; }
EOF
compile di "$WORK/di.c" "-std=gnu99 -O1"
bad=$(scan_pair "$WORK/di.s")
if [ -z "$bad" ]; then
    echo "di-load: OK (no self-clobbering load pair)"
else
    echo "di-load: FAIL (base-clobbering pair in: $bad)"; fail=1
fi

# (3) the fix path must actually have fired: when the pair overlaps the base,
# the low word is loaded first -- `L x,4+disp(b)` immediately followed by
# `L b,disp(b)`.  Guards against the allocator merely happening to avoid the
# overlap (which would leave the emit path untested).
rev=$(awk '
    { if (match($0, /^ +L +[0-9]+,4\+[0-9]+\([0-9]+\)$/)) {
        split($0,a,/[ ,()+]+/); d1=a[3];p1=a[5];b1=a[6]; prev=1; next }
      if (prev && match($0, /^ +L +[0-9]+,[0-9]+\([0-9]+\)$/)) {
        split($0,c,/[ ,()]+/); d2=c[3];p2=c[4];b2=c[5]
        if (d2==b1 && b2==b1 && p2==p1) print "rev" }
      prev=0 }' "$WORK/di.s")
if [ -n "$rev" ]; then
    echo "di-reversed: OK (overlapping pair loads the low word first)"
else
    echo "di-reversed: FAIL (no reversed pair found -- fix path never fired)"; fail=1
fi

[ $fail = 0 ] && echo "ALL CC370 TESTS PASSED" || echo "FAILURES"
exit $fail
