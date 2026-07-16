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

# (4) the __asm__ workaround: verbatim names, no truncation -> must NOT warn,
# even when the 8-char asm names share their first 7 characters.
cat > "$WORK/asm.c" <<'EOF'
extern int cfg_p __asm__("FTPCFGDP");
extern int cfg_f __asm__("FTPCFGDF");
int cfg_p = 1;
int cfg_f = 2;
EOF
compile asm "$WORK/asm.c"
if grep -q "collides with" "$WORK/diag"; then
    echo "asm-name: FAIL (false positive on verbatim __asm__ names)"; fail=1
else
    echo "asm-name: OK (verbatim asm names not truncated)"
fi

# (5) -Werror must promote the collision to a hard error (nonzero exit).
compile fnw "$WORK/fn.c" -Werror
if [ $? -ne 0 ]; then
    echo "werror: OK (collision is an error under -Werror)"
else
    echo "werror: FAIL (collision did not fail the build under -Werror)"; fail=1
fi

[ $fail = 0 ] && echo "ALL CC370 TESTS PASSED" || echo "FAILURES"
exit $fail
