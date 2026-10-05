#!/bin/sh
# The cc370 driver (#808), run from an installed tree.
#
#   driver.sh PREFIX        PREFIX = an installed cc370 tree with NO libc370
#                           of its own (make test-driver installs one)
#
# A stand-in libc370 (a libc.a holding @@CRT0, as libc370 >= 2.3.0) goes under
# PREFIX/cc370/libc370/ so the link checks run; it is removed afterwards.
#
#   sev4       an as370 warning (rc 4) keeps the object and the driver rc 0
#   sev8       an as370 error still fails the driver and leaves no object
#   multi-o    -c with several sources and -o is refused
#   tgt-help   --target-help prints cc1's target options and succeeds
#   flo-*      -flinker-output= takes xmit or iebcopy, also on a link alone
#   member     an -o that is no member name is refused when a wrapper is made
#   libgcc     -print-libgcc-file-name names the companion library
#   help-url   --help sends bug reports to the cc370 issue tracker
set -u
P=$1
CC="$P/bin/cc370"; AS="$P/cc370/bin/as370"; AR="$P/cc370/bin/ar370"
L="$P/cc370/libc370"
[ -x "$CC" ] || { echo "driver: no cc370 under $P"; exit 2; }
[ -e "$P/cc370/lib/crt0.o" ] && { echo "driver: $P has a crt0.o of its own -- the test needs a tree without libc370"; exit 2; }
WORK=$(mktemp -d "${TMPDIR:-/tmp}/cc370driver.XXXXXX") || exit 2
trap 'rm -rf "$WORK" "$L"' 0
fail=0
ok()  { echo "driver: OK   $*"; }
bad() { echo "driver: FAIL $*"; fail=1; }

mkdir -p "$L/lib"
printf '@@CRT0   CSECT\n         BR    14\n         END\n' > "$WORK/crt0.s"
printf 'FAKEFN   CSECT\n         BR    14\n         END\n' > "$WORK/fakefn.s"
"$AS" -o "$WORK/crt0.o" "$WORK/crt0.s" && "$AS" -o "$WORK/fakefn.o" "$WORK/fakefn.s" \
    && "$AR" rc "$L/lib/libc.a" "$WORK/crt0.o" "$WORK/fakefn.o" >/dev/null || { echo "driver: cannot build the stand-in"; exit 2; }

printf 'int f(void) { return 1; }\n__asm__("         DC    F%s2147483648%s");\n' "'" "'" > "$WORK/w.c"
"$CC" -c "$WORK/w.c" -o "$WORK/w.o" >"$WORK/d" 2>&1; rc=$?
if [ $rc -eq 0 ] && [ -s "$WORK/w.o" ] && grep -q IFO203 "$WORK/d"; then
    ok "sev4: IFO203 shown, rc 0, object kept"
else
    bad "sev4: rc $rc, object $( [ -s "$WORK/w.o" ] && echo kept || echo missing): $(head -2 "$WORK/d")"
fi

printf 'int f(void) { return 1; }\n__asm__("         BOGUSOP 1");\n' > "$WORK/e.c"
"$CC" -c "$WORK/e.c" -o "$WORK/e.o" >"$WORK/d" 2>&1; rc=$?
if [ $rc -ne 0 ] && [ ! -e "$WORK/e.o" ]; then
    ok "sev8: rc $rc, no object"
else
    bad "sev8: rc $rc, object $( [ -e "$WORK/e.o" ] && echo written || echo missing)"
fi

printf 'int a(void) { return 1; }\n' > "$WORK/a.c"
printf 'int b(void) { return 2; }\n' > "$WORK/b.c"
"$CC" -c "$WORK/a.c" "$WORK/b.c" -o "$WORK/ab.o" >"$WORK/d" 2>&1; rc=$?
if [ $rc -ne 0 ] && [ ! -e "$WORK/ab.o" ] && grep -q 'multiple files' "$WORK/d"; then
    ok "multi-o: refused, rc $rc"
else
    bad "multi-o: rc $rc: $(head -2 "$WORK/d")"
fi

"$CC" --target-help >"$WORK/d" 2>&1; rc=$?
if [ $rc -eq 0 ] && grep -q 'Target specific options' "$WORK/d" && ! grep -q ld370 "$WORK/d"; then
    ok "tgt-help: rc 0, no link"
else
    bad "tgt-help: rc $rc: $(grep -v '^  ' "$WORK/d" | head -2)"
fi

"$CC" -flinker-output=foo -c "$WORK/a.c" -o "$WORK/a.o" >"$WORK/d" 2>&1; rc=$?
if [ $rc -ne 0 ] && grep -q 'takes xmit or iebcopy' "$WORK/d"; then
    ok "flo-compile: rc $rc"
else
    bad "flo-compile: rc $rc: $(head -2 "$WORK/d")"
fi
"$CC" -c "$WORK/a.c" -o "$WORK/a.o" 2>/dev/null
"$CC" -flinker-output=foo "$WORK/a.o" -o "$WORK/flo" >"$WORK/d" 2>&1; rc=$?
if [ $rc -ne 0 ] && grep -q 'takes xmit or iebcopy' "$WORK/d" && [ ! -e "$WORK/flo" ]; then
    ok "flo-link: rc $rc, nothing linked"
else
    bad "flo-link: rc $rc: $(head -2 "$WORK/d")"
fi
"$CC" -flinker-output=xmit "$WORK/a.o" -o "$WORK/flo" >"$WORK/d" 2>&1; rc=$?
if [ $rc -eq 0 ] && [ -s "$WORK/flo" ] && [ -s "$WORK/flo.xmit" ]; then
    ok "flo-xmit: member and wrapper written"
else
    bad "flo-xmit: rc $rc: $(head -2 "$WORK/d")"
fi

"$CC" -flinker-output=xmit "$WORK/a.o" -o "$WORK/my_prog" >"$WORK/d" 2>&1; rc=$?
if [ $rc -ne 0 ] && grep -qi 'member name' "$WORK/d" && [ ! -e "$WORK/my_prog.xmit" ]; then
    ok "member: my_prog refused, rc $rc"
else
    bad "member: rc $rc: $(head -2 "$WORK/d")"
fi

case $("$CC" -print-libgcc-file-name) in
    */libcc370rt.a) ok "libgcc: libcc370rt.a" ;;
    *) bad "libgcc: $("$CC" -print-libgcc-file-name)" ;;
esac

if "$CC" --help 2>&1 | grep -q 'github.com/mvslovers/cc370/issues' \
   && ! "$CC" --help 2>&1 | grep -q 'gcc.gnu.org'; then
    ok "help-url: cc370 issue tracker"
else
    bad "help-url: $("$CC" --help 2>&1 | grep -i -A1 'bug' | tail -1)"
fi
# -V and -h as everywhere (#811); --version is one line, no GCC banner; -b and
# -VVERSION are refused instead of running `ogus-gcc-...' (#833)
v=$("$CC" --version 2>&1)
if [ "$("$CC" -V 2>&1)" = "$v" ] && [ "$(printf '%s\n' "$v" | wc -l | tr -d ' ')" = 1 ] \
   && printf '%s' "$v" | grep -q '^cc370 .* based on GCC 3\.4\.6$'; then
    ok "version: -V = --version, one line"
else
    bad "version: $(printf '%s' "$v" | head -3)"
fi
"$CC" -h 2>&1 | grep -q '^Usage: cc370' && ok "-h shows the usage" || bad "-h: $("$CC" -h 2>&1 | head -1)"
for a in -bogus -V3.4; do
    "$CC" $a -c "$WORK/a.c" -o "$WORK/b.o" >"$WORK/d" 2>&1; rc=$?
    if [ $rc -ne 0 ] && grep -q 'cc370 has one of each' "$WORK/d" && ! grep -q "couldn't run" "$WORK/d"; then
        ok "$a refused, rc $rc"
    else
        bad "$a: rc $rc: $(head -1 "$WORK/d")"
    fi
done
# -pipe is accepted and changes nothing: as370 reads a file (#831)
"$CC" -pipe -c "$WORK/a.c" -o "$WORK/pp.o" >"$WORK/d" 2>&1; rc=$?
if [ $rc -eq 0 ] && cmp -s "$WORK/pp.o" "$WORK/a.o"; then ok "-pipe: same object, rc 0"
else bad "-pipe: rc $rc: $(head -1 "$WORK/d")"; fi
# weak references end to end: __CC370_WEAK__ is predefined; an unresolved weak
# reference links rc 0 as 0 and autocall does not pull its definer from libc.a
"$CC" -E -dM - </dev/null 2>/dev/null | grep -q '^#define __CC370_WEAK__ 1$' && ok "__CC370_WEAK__ predefined" || bad "__CC370_WEAK__ missing"
printf 'extern void __premain(void) __attribute__((weak));
int main(void) { if (__premain) __premain(); return 0; }
' > "$WORK/wk.c"
printf '@@PREMAI CSECT\n         BR    14\n         END\n' > "$WORK/pm.s"
"$AS" -o "$WORK/pm.o" "$WORK/pm.s" && "$AR" rc "$L/lib/libc.a" "$WORK/crt0.o" "$WORK/fakefn.o" "$WORK/pm.o" >/dev/null
"$CC" -O1 "$WORK/wk.c" -o "$WORK/wk" -Wl,--map,"$WORK/wk.map" >"$WORK/d" 2>&1; rc=$?
if [ $rc -eq 0 ] && grep -q '@@PREMAI  WX' "$WORK/wk.map" && ! grep -q 'pm.o' "$WORK/wk.map"; then
    ok "weak reference: rc 0, left unresolved, not autocalled from libc.a"
else bad "weak link: rc $rc: $(head -2 "$WORK/d")"; fi
exit $fail
