#!/bin/sh
# cc370's prologue macros against libc370's originals (#688):
#   check.sh [ROOT...]
#
# PDPPRLG and PDPEPIL no longer call the IBM macros SAVE and RETURN; they write
# out what those generate.  The rule for that change is that no object deck
# moves.  So every source under the ROOTs that uses the macros is assembled
# twice with the SAME as370:
#
#   old  -I $LIBC370/maclib -I $LIBC370/sysmac           libc370's members
#   new  -I macros -I $LIBC370/maclib -I $LIBC370/sysmac  cc370's members first
#
# and the two decks must be identical.  A source that assembles on one side
# only is reported on its own; one that assembles on neither is counted and
# left alone (it needs macros this path does not have).
#
# Default ROOT is the libc370 checkout ($LIBC370, ../libc370 beside this repo).
cd "$(dirname "$0")/../.." || exit 2                  # -> the cc370 checkout
LIBC370=${LIBC370:-../libc370}
AS370=${AS370:-./as370/as370}
[ -x "$AS370" ] || { echo "macros: $AS370 not built (make tools)"; exit 2; }
[ -d "$LIBC370/maclib" ] || { echo "macros: libc370 not found at $LIBC370 (set LIBC370=)"; exit 2; }
[ $# -gt 0 ] || set -- "$LIBC370"
export ASMDATE=01/01/26 ASMTIME=00.00

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT INT TERM

find "$@" \( -name '*.s' -o -name '*.asm' \) -not -path '*/.git/*' -print0 2>/dev/null |
    xargs -0 grep -liE 'PDPPRLG|PDPEPIL|COPY +PDPTOP' 2>/dev/null | sort > "$TMP/list"

checked=0; same=0; moved=0; neither=0; oneside=0
while IFS= read -r src; do
    checked=$((checked + 1))
    "$AS370" -I "$LIBC370/maclib" -I "$LIBC370/sysmac" -o "$TMP/old.obj" "$src" >/dev/null 2>&1; orc=$?
    "$AS370" -I macros -I "$LIBC370/maclib" -I "$LIBC370/sysmac" -o "$TMP/new.obj" "$src" >/dev/null 2>&1; nrc=$?
    if [ $orc -ge 8 ] && [ $nrc -ge 8 ]; then neither=$((neither + 1)); continue; fi
    if [ $orc -ge 8 ] || [ $nrc -ge 8 ]; then
        echo "macros: $src assembles on one side only (old rc $orc, new rc $nrc)"
        oneside=$((oneside + 1)); continue
    fi
    if cmp -s "$TMP/old.obj" "$TMP/new.obj" && [ $orc = $nrc ]; then
        same=$((same + 1))
    else
        echo "macros: $src MOVED (old rc $orc, new rc $nrc)"; moved=$((moved + 1))
    fi
done < "$TMP/list"

echo "macros: $checked sources use the macros; $same identical, $moved moved, $oneside on one side only, $neither assemble on neither"
[ $checked -gt 0 ] || { echo "macros: nothing found under $*"; exit 2; }
[ $moved = 0 ] && [ $oneside = 0 ]
