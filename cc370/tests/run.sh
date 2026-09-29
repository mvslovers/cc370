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

# --- issue #468: a 64-bit shift left was emitted as SLDA, the ARITHMETIC ---
# double shift, which keeps bit 0 of the even register and shifts only the
# 63-bit magnitude -- so (unsigned long long)0xFFFFFFFF << 32 came back as
# 7FFFFFFF00000000.  A C left shift is logical on the bit pattern: SLDL.

# (1) the issue's three functions plus a variable shift count: no SLDA, and
# one SLDL each -- the count guards against the shift being lowered to
# something else entirely, which would also have no SLDA.
cat > "$WORK/shl.c" <<'EOF'
unsigned long long shl32u(unsigned long h) { return (unsigned long long)h << 32; }
long long          shl32s(long h)          { return (long long)h << 32; }
unsigned long long join(unsigned long h, unsigned long l) { return ((unsigned long long)h << 32) | l; }
unsigned long long shlv(unsigned long long x, int n) { return x << n; }
EOF
compile shl "$WORK/shl.c" "-std=gnu99 -O1"
slda=$(grep -c '^ *SLDA ' "$WORK/shl.s")
sldl=$(grep -c '^ *SLDL ' "$WORK/shl.s")
if [ "$slda" = 0 ] && [ "$sldl" -ge 4 ]; then
    echo "di-shl: OK (no SLDA, $sldl SLDL)"
else
    echo "di-shl: FAIL ($slda SLDA, $sldl SLDL; want 0 and >= 4)"; fail=1
fi

# (2) control: a signed 64-bit shift RIGHT is arithmetic and must stay SRDA.
cat > "$WORK/sra.c" <<'EOF'
long long sra3(long long x) { return x >> 3; }
EOF
compile sra "$WORK/sra.c" "-std=gnu99 -O1"
if grep -q '^ *SRDA ' "$WORK/sra.s"; then
    echo "di-sra: OK (signed shift right is still SRDA)"
else
    echo "di-sra: FAIL (no SRDA for a signed 64-bit shift right)"; fail=1
fi

# --- issue #470: a libcall's name is the libgcc name cut to 8 characters, ---
# and four pairs cut to the same one: __fixunssfdi/__fixunsdfdi -> @@FIXUNS,
# __floatdisf/__floatdidf -> @@FLOATD, __popcountsi2/__popcountdi2 ->
# @@POPCOU, __paritysi2/__paritydi2 -> @@PARITY.  One library member cannot
# serve two signatures.  Each call must now name its own helper.

# (1) each function below calls exactly one helper, and each a different one.
cat > "$WORK/lf.c" <<'EOF'
unsigned long long fxunsf(float f)  { return (unsigned long long)f; }
unsigned long long fxundf(double d) { return (unsigned long long)d; }
float              fltdsf(long long x) { return (float)x; }
double             fltddf(long long x) { return (double)x; }
int popcsi(unsigned x)           { return __builtin_popcount(x); }
int popcdi(unsigned long long x) { return __builtin_popcountll(x); }
int partsi(unsigned x)           { return __builtin_parity(x); }
int partdi(unsigned long long x) { return __builtin_parityll(x); }
EOF
compile lf "$WORK/lf.c" "-std=gnu99 -O1"
got=$(awk '/^\* X-func/{f=$3} /V\(@@/{match($0,/V\([^)]*\)/); print f "=" substr($0,RSTART+2,RLENGTH-3)}' "$WORK/lf.s" | tr '\n' ' ')
want="fxunsf=@@FXUNSF fxundf=@@FXUNDF fltdsf=@@FLTDSF fltddf=@@FLTDDF popcsi=@@POPCSI popcdi=@@POPCDI partsi=@@PARTSI partdi=@@PARTDI "
if [ "$got" = "$want" ]; then
    echo "libcall-names: OK (eight helpers, eight names)"
else
    echo "libcall-names: FAIL"; echo "   got:  $got"; echo "   want: $want"; fail=1
fi

# (2) control: the helpers whose names did not collide keep them -- libc370
# defines the first six, so moving one would break every consumer's link.
cat > "$WORK/lk.c" <<'EOF'
long long          mul(long long a, long long b) { return a * b; }
long long          dv(long long a, long long b)  { return a / b; }
long long          md(long long a, long long b)  { return a % b; }
unsigned long long ud(unsigned long long a, unsigned long long b) { return a / b; }
unsigned long long um(unsigned long long a, unsigned long long b) { return a % b; }
long long          ng(long long a) { return -a; }
long long          fxdf(double d) { return (long long)d; }
long long          fxsf(float f)  { return (long long)f; }
EOF
compile lk "$WORK/lk.c" "-std=gnu99 -O1"
got=$(grep -o 'V(@@[A-Z0-9@]*)' "$WORK/lk.s" | tr '\n' ' ')
want="V(@@MULDI3) V(@@DIVDI3) V(@@MODDI3) V(@@UDIVDI) V(@@UMODDI) V(@@NEGDI2) V(@@FIXDFD) V(@@FIXSFD) "
if [ "$got" = "$want" ]; then
    echo "libcall-keep: OK (the non-colliding names are unchanged)"
else
    echo "libcall-keep: FAIL"; echo "   got:  $got"; echo "   want: $want"; fail=1
fi

# --- issue #484: a wide character constant must carry the same EBCDIC value ---
# as a narrow one and as the element of a wide string literal.  The string
# element is emitted byte by byte through MAP_OUTCHAR, so the constant is
# mapped the same way, and a numeric escape is pre-imaged on the wide path as
# it is on the narrow one, so that it stays the literal value in both.
# Printable bytes leave as C'..' and become EBCDIC in the assembler: C'a' is
# X'81'.
cat > "$WORK/wc.c" <<'EOF'
int wa = L'a';
int na = 'a';
int wn = L'\n';
int nn = '\n';
int wx = L'\x81';
int nx = '\x81';
int wy = L'\x141';
const int sa[] = L"a";
const int sn[] = L"\n";
const int sx[] = L"\x81";
const int sy[] = L"\x141";
EOF
compile wc "$WORK/wc.c"
# One line per symbol: its DC operands, up to the terminating element.
got=$(awk '/ EQU /{if (s) print s; s=$1 ":"; next}
           /^[[:space:]]+DC[[:space:]]/{s=s " " $2}
           END{print s}' "$WORK/wc.s" | sed "s/ X'0' X'0' X'0' X'0'\$//")
want="WA: F'129'
NA: F'129'
WN: F'21'
NN: F'21'
WX: F'129'
NX: F'129'
WY: F'321'
SA: X'0' X'0' X'0' C'a'
SN: X'0' X'0' X'0' X'15'
SX: X'0' X'0' X'0' C'a'
SY: X'0' X'0' X'1' X'41'"
if [ "$got" = "$want" ]; then
    echo "wide-charconst: OK (L'x' == 'x' == L\"x\"[0], escapes literal)"
else
    echo "wide-charconst: FAIL"; echo "   got:"; echo "$got" | sed 's/^/      /'
    echo "   want:"; echo "$want" | sed 's/^/      /'; fail=1
fi

# --- issue #477: builtin folds must use the target (EBCDIC) value ---
# A string literal stays in the host charset until output, so a fold that
# turns a string byte into a value (putchar/fputc of a one-character string)
# or into an ordering (strcmp/strncmp/memcmp of two literals) must map it
# first.  One line per function: every operand that carries the folded value.
# The comparisons are chosen so that ASCII and EBCDIC disagree in both
# directions: 'a' < 'B' in EBCDIC (X'81' < X'C2'), '1' > 'a' (X'F1' > X'81').
cat > "$WORK/bf.c" <<'EOF'
typedef struct FILE FILE;
int printf(const char *, ...);
int fprintf(FILE *, const char *, ...);
int fputs(const char *, FILE *);
int strcmp(const char *, const char *);
int strncmp(const char *, const char *, __SIZE_TYPE__);
int memcmp(const void *, const void *, __SIZE_TYPE__);
void pa(void)        { printf("A"); }
void pn(void)        { printf("\n"); }
void px(void)        { printf("\x81"); }
void fa(FILE *f)     { fputs("A", f); }
void fp(FILE *f)     { fprintf(f, "A"); }
int  c1(void)        { return strcmp("a", "B"); }
int  c2(void)        { return strcmp("1", "a"); }
int  c3(void)        { return strncmp("a", "B", 1); }
int  c4(void)        { return memcmp("a", "B", 1); }
int  c5(void)        { return strcmp("ab", "ab"); }
int  c6(void)        { return strncmp("ab", "ac", 1); }
EOF
compile bf "$WORK/bf.c" "-O1"
got=$(awk '/^\* X-func/{if (f) print s; f=$3; s=f ":"; next}
           /=F.-?[0-9]+.|LA +15,|SLR +15,15|L +15,=V\(/{sub(/^[ \t]+/, ""); gsub(/[ \t]+/, " "); s=s " [" $0 "]"}
           END{print s}' "$WORK/bf.s")
want="pa: [MVC 88(4,13),=F'193'] [L 15,=V(PUTCHAR)]
pn: [MVC 88(4,13),=F'21'] [L 15,=V(PUTCHAR)]
px: [MVC 88(4,13),=F'129'] [L 15,=V(PUTCHAR)]
fa: [MVC 88(4,13),=F'193'] [L 15,=V(FPUTC)]
fp: [MVC 88(4,13),=F'193'] [L 15,=V(FPUTC)]
c1: [L 15,=F'-1']
c2: [LA 15,1(0,0)]
c3: [L 15,=F'-1']
c4: [L 15,=F'-1']
c5: [SLR 15,15]
c6: [SLR 15,15]"
if [ "$got" = "$want" ]; then
    echo "builtin-fold-ebcdic: OK (putchar/fputc get EBCDIC, literal compares in EBCDIC order)"
else
    echo "builtin-fold-ebcdic: FAIL"; echo "   got:"; echo "$got" | sed 's/^/      /'
    echo "   want:"; echo "$want" | sed 's/^/      /'; fail=1
fi

[ $fail = 0 ] && echo "ALL CC370 TESTS PASSED" || echo "FAILURES"
exit $fail
