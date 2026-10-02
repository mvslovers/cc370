#!/bin/sh
# Smoke-test a release tarball where it was built:  smoke.sh TARBALL [--static]
#
# Unpacks it into a scratch directory -- somewhere else than it was built, so
# a path baked in at build time shows -- and checks what a user does first:
#   - every binary reports VERSION (the commit is test-version's business)
#   - cc370 compiles and assembles a C file with nothing but the tarball: the
#     prologue macros ship with it (#688), libc370 is not needed for -c
#   - the runtime is where mbt looks for it (<sysroot>/lib/libcc370rt.a)
#   - with --static, no binary is dynamically linked (the Linux tarballs)
set -u
tarball=$1; static=${2:-}
ver=$(tr -d ' \t\r\n' < "$(dirname "$0")/../VERSION")
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
tar -C "$tmp" -xzf "$tarball" || { echo "smoke: cannot unpack $tarball"; exit 1; }
root=$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)
fail=0
ok()  { echo "smoke: OK   $*"; }
bad() { echo "smoke: FAIL $*"; fail=1; }

for t in cc370 as370 ld370 ar370 file370 xmit370 cmplmd370 dasm370 idrdump370; do
    v=$("$root/bin/$t" --version 2>&1 | head -1)
    case $v in "$t $ver "*) ok "$v" ;; *) bad "$t --version: '$v'" ;; esac
done

printf 'long long f(long long a, long long b) { return a / b; }\n' > "$tmp/t.c"
if "$root/bin/cc370" -O1 -c "$tmp/t.c" -o "$tmp/t.o" && [ -s "$tmp/t.o" ]; then
    ok "cc370 -c compiles and assembles with the tarball alone"
else
    bad "cc370 -c t.c"
fi

[ -s "$root/cc370/lib/libcc370rt.a" ] && ok "cc370/lib/libcc370rt.a present" \
    || bad "cc370/lib/libcc370rt.a missing"

if [ "$static" = --static ]; then
    dyn=$(find "$root" -type f -perm -u+x | while read -r f; do
        file "$f" | grep -q 'ELF' || continue
        file "$f" | grep -q 'dynamically linked' && echo "$f"
    done)
    [ -z "$dyn" ] && ok "every ELF binary is statically linked" \
        || bad "dynamically linked: $(echo $dyn | sed "s|$root/||g")"
fi
exit $fail
