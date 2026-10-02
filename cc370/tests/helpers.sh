#!/bin/sh
# cc370 runtime-helper interface tests (#685).
#
# The compiler emits calls to helper routines it does not inline -- 64-bit
# multiply/divide, float <-> long long conversions, popcount/parity/clz/ctz,
# the -ftrapv checks.  Their external names are an interface with whatever
# library provides them (libc370 today, libcc370rt.a once #687 lands), and
# libc370#190 showed what a silent rename costs.  Two stages:
#
#   1. emission -- every case below compiles one construct with cc1 and must
#      reference exactly the helpers listed for it.  A helper that appears,
#      disappears or is renamed fails here.  Needs only cc1, so it always runs.
#      It sees =V(...) literals only, which is how cc370 calls a helper today;
#      a helper reached through DC V(...) or an EXTRN would be invisible to it.
#
#   2. link -- every case is assembled and linked against the runtime, and
#      must leave nothing unresolved.  Needs a sysroot (macros for as370,
#      libraries for ld370); without one the stage is skipped, not failed.
#      Cases known to fail carry an XFAIL naming their issue: they report but
#      do not fail the suite -- as long as the link fails exactly on the
#      expected helpers and nothing else.  One that starts to link FAILS
#      ("XPASS") so the marker is removed in the same change that fixed it.
#
# Overrides: CC1=, AS370=, LD370=, SYSROOT=, RTLIBS= (the libraries the link
# stage searches, default "-lc").
cd "$(dirname "$0")" || exit 2
ROOT=../..
CC1=${CC1:-$ROOT/build/gcc/cc1}
AS370=${AS370:-$ROOT/as370/as370}
LD370=${LD370:-$ROOT/ld370/ld370}
RTLIBS=${RTLIBS:--lc}
if [ ! -x "$CC1" ]; then
    echo "cc1 not found at $CC1 -- run 'make compiler' first (or set CC1=)" >&2
    exit 2
fi
if [ -z "$SYSROOT" ]; then
    drv=$(command -v cc370 2>/dev/null)
    [ -n "$drv" ] && SYSROOT=$(dirname "$drv")/../cc370
fi
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cc370helpers.XXXXXX") || exit 2
trap 'rm -rf "$WORK"' 0
fail=0

link=1
if [ ! -f "$SYSROOT/lib/libc.a" ] || [ ! -d "$SYSROOT/macros" ]; then
    echo "link stage: SKIPPED (no sysroot with lib/libc.a and macros/ -- set SYSROOT=)"
    link=0
elif [ ! -x "$AS370" ] || [ ! -x "$LD370" ]; then
    echo "link stage: SKIPPED ($AS370 or $LD370 not built -- run 'make tools')"
    link=0
fi

# case NAME FLAGS EXPECTED XFAIL SOURCE
#   EXPECTED  the helper names the case must reference, sorted, space-separated
#             ("-" = none: the construct must stay inline)
#   XFAIL     "-", or the issue that will make the link stage pass
case_ () {
    name=$1 flags=$2 want=$3 xfail=$4 src=$5
    printf '%s\n' "$src" > "$WORK/$name.c"
    if ! $CC1 -quiet -std=gnu99 -O1 $flags "$WORK/$name.c" -o "$WORK/$name.s" >"$WORK/diag" 2>&1; then
        echo "$name: FAIL (cc1)"; sed 's/^/    /' "$WORK/diag"; fail=1; return
    fi
    got=$(grep -o '=V([^)]*)' "$WORK/$name.s" | sed 's/=V(//; s/)//' | sort -u | tr '\n' ' ' | sed 's/ $//')
    [ -z "$got" ] && got=-
    if [ "$got" != "$want" ]; then
        echo "$name: FAIL (emits '$got', want '$want')"; fail=1; return
    fi
    [ "$link" = 1 ] || { echo "$name: OK (emits $got)"; return; }

    if ! "$AS370" -I "$SYSROOT/macros" -o "$WORK/$name.o" "$WORK/$name.s" >"$WORK/asm" 2>&1; then
        echo "$name: FAIL (as370)"; sed 's/^/    /' "$WORK/asm" | head -5; fail=1; return
    fi
    # Entry at the probe itself: no startup object, so the only thing the
    # libraries are asked for is the helper.  --warn-shadow names a helper
    # defined twice, which must not happen either.
    "$LD370" --warn-shadow --entry PROBE -o "$WORK/$name.lm" "$WORK/$name.o" \
        -L "$SYSROOT/lib" $RTLIBS >"$WORK/ld" 2>&1
    rc=$?
    if grep -q "also defined by" "$WORK/ld"; then
        echo "$name: FAIL (helper defined twice)"; grep "also defined by" "$WORK/ld" | sed 's/^/    /'; fail=1; return
    fi
    if [ $rc = 0 ]; then
        if [ "$xfail" != - ]; then
            echo "$name: XPASS (links now -- remove the XFAIL for $xfail)"; fail=1
        else
            echo "$name: OK (emits $got, links)"
        fi
    else
        missing=$(sed -n '/unresolved external reference/,/unresolved external(s)/p' "$WORK/ld" | grep '^    ' | tr -d ' ' | sort -u | tr '\n' ' ' | sed 's/ $//')
        # An XFAIL covers exactly the helpers it was written for: a link that
        # also misses something else, or fails for another reason (nothing
        # unresolved at all), is a real failure.
        if [ "$xfail" != - ] && [ "$missing" = "$want" ]; then
            echo "$name: XFAIL $xfail (unresolved: $missing)"
        else
            echo "$name: FAIL (unresolved: ${missing:-none -- ld370 failed otherwise})"
            sed 's/^/    /' "$WORK/ld" | head -5; fail=1
        fi
    fi
}

LL='typedef long long ll; typedef unsigned long long ull;'

# --- 64-bit integer arithmetic ---
case_ muldi3 "" "@@MULDI3" - "$LL ll probe(ll a, ll b) { return a * b; }"
case_ divdi3 "" "@@DIVDI3" - "$LL ll probe(ll a, ll b) { return a / b; }"
case_ moddi3 "" "@@MODDI3" - "$LL ll probe(ll a, ll b) { return a % b; }"
case_ udivdi3 "" "@@UDIVDI" - "$LL ull probe(ull a, ull b) { return a / b; }"
case_ umoddi3 "" "@@UMODDI" - "$LL ull probe(ull a, ull b) { return a % b; }"
case_ negdi2 "" "@@NEGDI2" - "$LL ll probe(ll a) { return -a; }"

# --- conversions ---
case_ fixdfdi "" "@@FIXDFD" - "$LL ll probe(double d) { return (ll)d; }"
case_ fixsfdi "" "@@FIXSFD" - "$LL ll probe(float f) { return (ll)f; }"
case_ fxundf "" "@@FXUNDF" - "$LL ull probe(double d) { return (ull)d; }"
case_ fxunsf "" "@@FXUNSF" - "$LL ull probe(float f) { return (ull)f; }"
case_ fltddf "" "@@FLTDDF" - "$LL double probe(ll a) { return (double)a; }"
case_ fltdsf "" "@@FLTDSF" - "$LL float probe(ll a) { return (float)a; }"
# unsigned long long -> float/double: a signed conversion plus a sign test,
# and the sign test is where @@CMPDI2 comes from -- not from a comparison in
# the source, which is inlined (inl-cmp64 below).
case_ ufltdsf "" "@@CMPDI2 @@FLTDSF" - "$LL float probe(ull a) { return (float)a; }"
case_ ufltddf "" "@@CMPDI2 @@FLTDDF" - "$LL double probe(ull a) { return (double)a; }"

# --- builtins ---
case_ popcsi "" "@@POPCSI" - "int probe(unsigned x) { return __builtin_popcount(x); }"
case_ popcdi "" "@@POPCDI" - "$LL int probe(ull x) { return __builtin_popcountll(x); }"
case_ partsi "" "@@PARTSI" - "int probe(unsigned x) { return __builtin_parity(x); }"
case_ partdi "" "@@PARTDI" - "$LL int probe(ull x) { return __builtin_parityll(x); }"
case_ clzsi2 "" "@@CLZSI2" - "int probe(unsigned x) { return __builtin_clz(x); }"
case_ clzdi2 "" "@@CLZDI2" - "$LL int probe(ull x) { return __builtin_clzll(x); }"
case_ ctzsi2 "" "@@CTZSI2" - "int probe(unsigned x) { return __builtin_ctz(x); }"
case_ ctzdi2 "" "@@CTZDI2" - "$LL int probe(ull x) { return __builtin_ctzll(x); }"
case_ ffsdi2 "" "@@FFSDI2" - "$LL int probe(ll x) { return __builtin_ffsll(x); }"
# SImode ffs is GCC's default libfunc: libc's ffs(), which libc370 lacks.
case_ ffssi "" "FFS" "#687" "int probe(int x) { return __builtin_ffs(x); }"

# --- -ftrapv: overflow-checking arithmetic; none of these exists yet ---
case_ addvdi3 "-ftrapv" "@@ADDVDI" "#687" "$LL ll probe(ll a, ll b) { return a + b; }"
case_ subvdi3 "-ftrapv" "@@SUBVDI" "#687" "$LL ll probe(ll a, ll b) { return a - b; }"
case_ mulvdi3 "-ftrapv" "@@MULVDI" "#687" "$LL ll probe(ll a, ll b) { return a * b; }"
case_ mulvsi3 "-ftrapv" "@@MULVSI" "#687" "int probe(int a, int b) { return a * b; }"
case_ negvdi2 "-ftrapv" "@@NEGVDI" "#687" "$LL ll probe(ll a) { return -a; }"

# --- must stay inline: a helper appearing here is a regression too ---
case_ inl-shl64 "" - - "$LL ull probe(ull a, int n) { return a << n; }"
case_ inl-shr64 "" - - "$LL ll probe(ll a, int n) { return a >> n; }"
case_ inl-add64 "" - - "$LL ll probe(ll a, ll b) { return a + b; }"
case_ inl-cmp64 "" - - "$LL int probe(ll a, ll b, ull c, ull d) { return (a < b) + (c < d) + (a == b); }"
case_ inl-div32 "" - - "unsigned probe(unsigned a, unsigned b) { return a / b + a % b; }"
case_ inl-dbl "" - - "double probe(double a, double b) { return a * b / (a + b); }"
case_ inl-cvt32 "" - - "int probe(double d, unsigned u) { return (int)d + (int)(double)u; }"
case_ inl-addv32 "-ftrapv" - - "int probe(int a, int b) { return a + b - b; }"

exit $fail
