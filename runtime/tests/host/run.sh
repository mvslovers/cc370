#!/bin/sh
# Host tests of libcc370rt.a's C (#687): each #includes the runtime sources
# and checks them against the host's native 64-bit arithmetic.  They prove
# the arithmetic, not the S/370 code -- runtime/tests/mvs/ holds the target
# tests, which run on MVS.  Moved from libc370's test/host with the sources.
CC=${CC:-cc}
cd "$(dirname "$0")" || exit 2
B=$(mktemp -d) || exit 2
trap 'rm -rf "$B"' EXIT
fail=0
for t in tstdi3 tstcnvdi tsttrapv; do
    if "$CC" -std=gnu99 -Wall -Wextra -Werror -O1 -o "$B/$t" "$t.c" && "$B/$t" > "$B/out" 2>&1; then
        echo "runtime $t: OK ($(tail -1 "$B/out" | sed 's/^ *total: *//'))"
    else
        echo "runtime $t: FAIL"; tail -5 "$B/out" 2>/dev/null; fail=1
    fi
done
exit $fail
