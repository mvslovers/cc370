#!/bin/sh
# Every binary reports the toolchain's one version, with the commit the tree is
# at:  version.sh BINARY...
#
#   <tool> <VERSION> (<commit>)                       the eight tools
#   cc370 <VERSION> (<commit>), based on GCC 3.4.6    the driver (build/gcc/xgcc)
#
# The expectation is derived here, from the VERSION file and git, and NOT from
# the generated header: a binary built before the last commit still agrees with
# a stale header, and catching that binary is the point (mvslovers/mbt#59).
# Outside a git checkout of this tree the commit is `unknown', as in
# common/mkversion.sh.
root=$(cd "$(dirname "$0")/../.." && pwd -P)
ver=$(tr -d ' \t\r\n' < "$root/VERSION")
commit=unknown
top=$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$top" ] && [ "$(cd "$top" && pwd -P)" = "$root" ]; then
    c=$(git -C "$root" rev-parse --short HEAD 2>/dev/null || true)
    if [ -n "$c" ]; then
        commit=$c
        git -C "$root" diff --quiet HEAD -- 2>/dev/null || commit="$c-dirty"
    fi
fi

fail=0
for b in "$@"; do
    name=$(basename "$b")
    case $name in
        xgcc|cc370) want="cc370 $ver ($commit), based on GCC 3.4.6" ;;
        *)          want="$name $ver ($commit)" ;;
    esac
    got=$("$b" --version 2>&1 | head -1)
    if [ "$got" = "$want" ]; then
        echo "version: OK   $got"
    else
        echo "version: FAIL $b -- got '$got', want '$want'"
        fail=1
    fi
done
exit $fail
