#!/bin/sh
# The second sysroot (#726): a libc370 linked in as <prefix>/cc370/libc370/.
#
#   sysroot.sh PREFIX        PREFIX = an installed cc370 tree with NO libc370
#                            of its own (make test-sysroot installs one)
#
# A minimal stand-in for libc370 goes under PREFIX/cc370/libc370/ -- one
# header, a libc.a with @@CRT0 and one function (libc370 >= 2.3.0), one macro --
# and the toolchain must find each of them there, through the driver alone:
#
#   header   cc370 -E sees fake370.h's #define
#   @@CRT0   autocall takes it from libc370/lib/libc.a (no startfile since #159)
#   -lc      the link resolves FAKEFN from libc370/lib/libc.a
#   macro    as370, run by the driver, expands FAKEMAC from libc370/macros
#
# The stand-in is removed again afterwards; PREFIX is otherwise untouched.
set -u
P=$1
CC="$P/bin/cc370"; AS="$P/cc370/bin/as370"; AR="$P/cc370/bin/ar370"
L="$P/cc370/libc370"
[ -x "$CC" ] || { echo "sysroot: no cc370 under $P"; exit 2; }
[ -e "$P/cc370/lib/crt0.o" ] && { echo "sysroot: $P has a crt0.o of its own -- the test needs a tree without libc370"; exit 2; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cc370sysroot.XXXXXX") || exit 2
trap 'rm -rf "$WORK" "$L"' 0
fail=0
ok()  { echo "sysroot: OK   $*"; }
bad() { echo "sysroot: FAIL $*"; fail=1; }

mkdir -p "$L/include" "$L/lib" "$L/macros"
printf '#define FAKE370 4242\nint fakefn(void);\n' > "$L/include/fake370.h"
printf '@@CRT0   CSECT\n         BR    14\n         END\n' > "$WORK/crt0.s"
printf 'FAKEFN   CSECT\n         SR    15,15\n         BR    14\n         END\n' > "$WORK/fakefn.s"
"$AS" -o "$WORK/crt0.o" "$WORK/crt0.s" && "$AS" -o "$WORK/fakefn.o" "$WORK/fakefn.s" \
    && "$AR" rc "$L/lib/libc.a" "$WORK/crt0.o" "$WORK/fakefn.o" >/dev/null || { echo "sysroot: cannot build the stand-in"; exit 2; }
printf '         MACRO\n&L       FAKEMAC\n&L       DC    F%s4243%s\n         MEND\n' "'" "'" > "$L/macros/fakemac.macro"

printf '#include <fake370.h>\nint v = FAKE370;\nint main(void) { return fakefn(); }\n' > "$WORK/t.c"
if "$CC" -E "$WORK/t.c" 2>"$WORK/e" | grep -q 'int v = 4242'; then
    ok "header from cc370/libc370/include"
else
    bad "header: $(head -2 "$WORK/e")"
fi

# the link on its own, no header involved, so each check stands alone
printf 'int fakefn(void);\nint main(void) { return fakefn(); }\n' > "$WORK/k.c"
if "$CC" -O1 "$WORK/k.c" -o "$WORK/t.lm" -Wl,--map,"$WORK/t.map" >"$WORK/l" 2>&1; then
    grep -q 'libc370/lib/libc.a(crt0.o)' "$WORK/t.map" && ok "@@CRT0 from cc370/libc370/lib/libc.a" \
        || bad "@@CRT0 not taken from libc370/lib/libc.a: $(grep -i crt0 "$WORK/t.map" | head -1)"
    grep -q 'libc370/lib/libc.a(fakefn.o)' "$WORK/t.map" && ok "-lc resolved from cc370/libc370/lib/libc.a" \
        || bad "FAKEFN not from libc370/lib/libc.a: $(grep -i fakefn "$WORK/t.map" | head -1)"
else
    bad "link: $(head -3 "$WORK/l")"
fi

printf 'T        CSECT\nX        FAKEMAC\n         END\n' > "$WORK/m.s"
if "$CC" -c "$WORK/m.s" -o "$WORK/m.o" >"$WORK/a" 2>&1 && [ -s "$WORK/m.o" ]; then
    ok "macro from cc370/libc370/macros (as370 run by the driver)"
else
    bad "macro: $(head -2 "$WORK/a")"
fi
exit $fail
