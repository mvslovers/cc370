#!/bin/sh
# Every binary reports the toolchain's one version, with the commit the tree is
# at:  version.sh BINARY...
#
#   <tool> <VERSION> (<commit>)                       the eight tools
#   cc370 <VERSION> (<commit>), based on GCC 3.4.6    the driver (build/gcc/xgcc)
#
# For the driver it also checks the predefined __CC370__ (#704):
# MAJOR*10000 + MINOR*100 + PATCH of VERSION, a pre-release suffix dropped.
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
    # -V is the short form in every tool, and -v is never the version (#811).
    # The driver is GCC's: -V there takes a target version, -v is verbose.
    case $name in
        xgcc|cc370) ;;
        *)
            got=$("$b" -V 2>&1 | head -1)
            if [ "$got" = "$want" ]; then echo "version: OK   $name -V"
            else echo "version: FAIL $b -V -- got '$got', want '$want'"; fail=1; fi
            if "$b" -v </dev/null 2>&1 | head -1 | grep -qF "$want"; then
                echo "version: FAIL $b -v prints the version; -v is verbose"; fail=1
            fi ;;
    esac
    case $name in
        xgcc|cc370)
            # the in-tree driver finds cc1 beside it only through -B
            num=$(echo "${ver%%-*}" | awk -F. '{ print $1 * 10000 + $2 * 100 + $3 }')
            mac=$("$b" -B"$(dirname "$b")/" -E -dM - </dev/null 2>&1 | sed -n 's/^#define __CC370__ //p')
            if [ "$mac" = "$num" ]; then
                echo "version: OK   __CC370__ $mac"
            else
                echo "version: FAIL $b -- __CC370__ is '$mac', want '$num'"
                fail=1
            fi ;;
    esac
done
exit $fail
