#!/bin/sh
# as370 against IFOX00 on the frozen libc370 corpus (cc370#23).
#
# Every module in manifest.tsv is assembled by the working tree's as370 with the
# frozen macro libraries beside it (-I maclib -I sysmac -I ccmacros, the order
# the host uses) and compared with ifox/<member>.obj, IFOX00's own deck from
# MVSTK5-REF (as370/tests/oracle/capture_libcorpus.py).  Like tests/ref, the
# comparison is every card before END -- the END card carries the translator
# IDR, which as370 does not reproduce -- and the deck sizes must agree.
#
# A module with no reference deck is counted, not failed: it is one IFOX00
# punched nothing for, or one whose cut deck failed the ESD-name check.
# ifox/excluded.tsv lists decks not used as an oracle (with the reason), and
# ifox/stamps.tsv the &SYSDATE/&SYSTIME IFOX00 put into a deck, which as370 is
# given through ASMDATE/ASMTIME for that module.
# Needs nothing outside this repository: no libc370 checkout, no MVS.
cd "$(dirname "$0")/../../.." || exit 2          # repo root
AS=./as370/as370
D=as370/tests/libcorpus
[ -x "$AS" ] || { echo "libcorpus: as370 not built"; exit 2; }
TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM
same=0; diff=0; noref=0; excl=0; n=0
grep -v '^#' "$D/manifest.tsv" | while IFS="$(printf '\t')" read -r mem path sha; do
    [ -n "$mem" ] || continue
    echo "$mem $path"
done > "$TMP/list"
while read -r mem path; do
    n=$((n + 1))
    ref="$D/ifox/$mem.obj"
    if grep -q "^$mem	" "$D/ifox/excluded.tsv" 2>/dev/null; then excl=$((excl + 1)); continue; fi
    if [ ! -f "$ref" ]; then noref=$((noref + 1)); continue; fi
    st=$(grep "^$mem	" "$D/ifox/stamps.tsv" 2>/dev/null)
    if [ -n "$st" ]; then
        ASMDATE=$(echo "$st" | cut -f2) ASMTIME=$(echo "$st" | cut -f3) \
            "$AS" "$D/src/$path" -I "$D/maclib" -I "$D/sysmac" -I "$D/ccmacros" -o "$TMP/a.obj" >/dev/null 2>&1
    else
        "$AS" "$D/src/$path" -I "$D/maclib" -I "$D/sysmac" -I "$D/ccmacros" -o "$TMP/a.obj" >/dev/null 2>&1
    fi
    rsz=$(wc -c < "$ref"); asz=$(wc -c < "$TMP/a.obj" 2>/dev/null || echo 0)
    nbe=$(( (rsz / 80 - 1) * 80 ))
    if [ "$rsz" = "$asz" ] && [ "$nbe" -gt 0 ]; then
        head -c "$nbe" "$TMP/a.obj" > "$TMP/x"; head -c "$nbe" "$ref" > "$TMP/y"
        if cmp -s "$TMP/x" "$TMP/y"; then same=$((same + 1)); continue; fi
    fi
    diff=$((diff + 1)); echo "libcorpus: $mem $path differs from IFOX00 (deck $asz vs $rsz bytes)"
done < "$TMP/list"
echo "libcorpus: $n modules, $same identical to IFOX00, $diff differ, $excl excluded, $noref without a reference deck"
[ "$diff" = 0 ]
