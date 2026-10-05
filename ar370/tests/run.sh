#!/bin/sh
# ar370 suite (#805).  Each check fails on the 1.2.0 binary: limits that
# dropped objects and symbols silently, member names cut to 16 bytes, the
# operation matched letter by letter, any file stored as a member.
cd "$(dirname "$0")/../.." || exit 2
AR=${AR370:-./ar370/ar370}; AS=./as370/as370; LD=./ld370/ld370
pass=0; fail=0
ok()  { echo "PASS: $1"; pass=$((pass+1)); return 0; }
bad() { echo "FAIL: $1"; fail=$((fail+1)); return 0; }
case "$AR" in /*) ;; *) AR="$PWD/$AR" ;; esac
for t in "$AR" "$AS" "$LD"; do [ -x "$t" ] || { echo "ar370 suite: $t not built"; exit 2; }; done
W=$(mktemp -d) || exit 2
trap 'rm -rf "$W"' EXIT INT TERM

# one object deck: a CSECT and eight entries, nine symbols
{
    echo "SYM9     CSECT"
    for e in E1 E2 E3 E4 E5 E6 E7 E8; do echo "         ENTRY $e"; done
    for e in E1 E2 E3 E4 E5 E6 E7 E8; do echo "$e       DC    F'0'" | awk '{printf "%-8s %s    %s\n",$1,$2,$3}'; done
    echo "         END"
} > "$W/sym9.s"
"$AS" "$W/sym9.s" -o "$W/sym9.o" || { echo "cannot assemble the fixture"; exit 2; }

# 1. no limit: 2050 objects, 18450 symbols (the old limits were 2048 / 16384)
mkdir "$W/many"
i=0; while [ $i -lt 2050 ]; do cp "$W/sym9.o" "$W/many/m$i.o"; i=$((i+1)); done
( cd "$W/many" && find . -name 'm*.o' | sort > ../list )
( cd "$W/many" && xargs "$AR" rc ../many.a < ../list ) 2>"$W/err"; r=$?
nm=$("$AR" t "$W/many.a" | awk '/^members:/{f=1;next} /^symbol table/{f=0} f' | wc -l | tr -d ' ')
ns=$("$AR" t "$W/many.a" | sed -n 's/^symbol table: \([0-9]*\) symbol.*/\1/p')
[ $r = 0 ] && [ "$nm" = 2050 ] && [ "$ns" = 18450 ] && ok "2050 objects and 18450 symbols are all stored" \
    || bad "limits: rc $r, $nm members, $ns symbols (want 2050, 18450)"

# 2. a long member name goes to the // table, t shows it whole, ld370 --include finds it
LN=averyveryverylongname
cp "$W/sym9.o" "$W/$LN.o"
"$AR" rc "$W/liblong.a" "$W/$LN.o" "$W/sym9.o" 2>"$W/err"; r=$?
if [ $r = 0 ] && "$AR" t "$W/liblong.a" | grep -qE "^  $LN\.o +[0-9]+ bytes$" && grep -q "//" "$W/liblong.a"; then
    ok "a 25-character member name is stored whole (GNU // table) and listed whole"
else bad "long name: rc $r, $(cat "$W/err")"; fi
"$LD" -o "$W/LNK" --include "$LN" -L "$W" -l long >"$W/ld.out" 2>&1; r=$?
[ $r -le 4 ] && [ -s "$W/LNK" ] && ok "ld370 --include finds the long-named member (rc $r)" \
    || bad "ld370 --include $LN: rc $r, $(head -2 "$W/ld.out")"

[ -x ./file370/file370 ] && { ./file370/file370 -v "$W/liblong.a" | grep -qE "^    member  $LN\.o +[0-9]+ bytes$" \
    && ok "file370 resolves the long name" || bad "file370 shows: $(./file370/file370 -v "$W/liblong.a" | grep member | head -1)"; }

# 3. a name ld370 cannot address is refused, not cut
LL=a123456789b123456789c123456789d123456789e123456789f123456789g1234
cp "$W/sym9.o" "$W/$LL.o"
"$AR" rc "$W/ll.a" "$W/$LL.o" 2>"$W/err"; r=$?
[ $r = 1 ] && grep -q "longer than 63" "$W/err" && [ ! -f "$W/ll.a" ] && ok "a 66-character name is refused, rc 1, no archive" \
    || bad "over-long name: rc $r, $(cat "$W/err")"

# 4. the operation is matched whole; --version anywhere first
( cd "$W" && "$AR" --version x >/dev/null ); r=$?
[ $r = 0 ] && [ ! -e "$W/x" ] && ok "--version x prints the version and creates nothing" || bad "--version x: rc $r, x exists: $([ -e "$W/x" ] && echo yes)"
"$AR" xr "$W/q.a" "$W/sym9.o" 2>"$W/err"; r=$?
[ $r = 2 ] && [ ! -e "$W/q.a" ] && grep -q "unknown operation" "$W/err" && ok "an operation with a stray letter is rc 2" || bad "xr: rc $r"
"$AR" -rc "$W/d.a" "$W/sym9.o"; r=$?
[ $r = 0 ] && [ -s "$W/d.a" ] && ok "-rc is accepted like rc" || bad "-rc: rc $r"
"$AR" --help > "$W/h" 2>&1; r=$?
[ $r = 0 ] && grep -q "replaced, not added" "$W/h" && ok "--help prints the usage, rc 0, and says r replaces" || bad "--help: rc $r"

# 5. only object decks are stored
printf 'int main(void){return 0;}\n' > "$W/hello.c"
"$AR" rc "$W/c.a" "$W/hello.c" 2>"$W/err"; r=$?
[ $r = 1 ] && grep -q "not an object deck" "$W/err" && [ ! -e "$W/c.a" ] && ok "a C source is refused, rc 1" || bad "hello.c: rc $r, $(cat "$W/err")"
"$AR" rc "$W/a2.a" "$W/liblong.a" 2>"$W/err"; r=$?
[ $r = 1 ] && grep -q "is an archive" "$W/err" && ok "an archive as input is refused, rc 1" || bad "archive input: rc $r, $(cat "$W/err")"

# 6. t names the member that defines each symbol, without the trailing /
"$AR" t "$W/liblong.a" > "$W/t"
grep -qE '^  SYM9 +sym9\.o$' "$W/t" && ! grep -q 'sym9.o/' "$W/t" && ok "t pairs each symbol with its member" || bad "t: $(head -8 "$W/t")"

# 7. control: an archive of short names is byte-identical to the 1.2.0 layout
#    (magic, "/", members) -- the long-name table appears only when needed
"$AR" rc "$W/s.a" "$W/sym9.o"
grep -q "//" "$W/s.a" && bad "a short-name archive carries a // member" || ok "no // member when no name needs it"

# 8. #811: a trailing v names each member written, as GNU ar; the archive is
#    the same as without it, and an unknown letter is still refused
"$AR" rcv "$W/v.a" "$W/sym9.o" > "$W/v.out"
"$AR" rc "$W/nv.a" "$W/sym9.o" > "$W/nv.out"
grep -qx 'a - sym9.o' "$W/v.out" && [ ! -s "$W/nv.out" ] && cmp -s "$W/v.a" "$W/nv.a" \
    && ok "rcv names each member; the archive is unchanged" || bad "rcv: $(cat "$W/v.out")"
"$AR" rcx "$W/x.a" "$W/sym9.o" 2>/dev/null; [ $? = 2 ] && ok "rcx is still an unknown operation" || bad "rcx accepted"

echo "ar370: $pass passed, $fail failed"
[ $fail = 0 ]
