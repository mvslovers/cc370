#!/bin/sh
# libc370 corpus regression gate (#23-lite).
#
# Assembles every non-wip libc370 .asm/.s module with as370 and checks each
# object deck's SHA256 against the committed manifest.
#
# SCOPE -- read this before trusting it. This is a REGRESSION guard: it catches
# an as370 change that alters any libc370 object deck ("did I move the corpus").
# It is NOT an oracle guard: it does not re-verify "today's bytes == IFOX00".
# The manifest baseline is byte-identical to IFOX00 by the historical 736/736
# validation, but this gate only enforces STABILITY of that baseline, not
# equivalence to it. Re-running the 910-module + sibling-repo corpus against
# committed IFOX00 references is #23-full.
#
#   check.sh              verify current as370 output against the manifest
#   check.sh --generate   rewrite the manifest from current as370 output
#
# Override the libc370 checkout with LIBC370=/path (default ../../libc370).
cd "$(dirname "$0")/../.." || exit 2                 # -> as370/
LIBC370=${LIBC370:-../../libc370}
MAC="-I $LIBC370/maclib -I $LIBC370/sysmac"
MANIFEST=tests/corpus/libc370.manifest
TMP=/tmp/as370corpus.$$

# Pin the assembly date/time so the manifest is reproducible on any wall clock.
# as370 stamps the END-record IDR with the system date (g_sysdate), and a few
# modules embed &SYSDATE/&SYSTIME in their object (e.g. @@crt0/@@crt1/@@crtsvc
# carry an assembly-timestamp eye-catcher) -- both would drift the SHAs by the
# day/minute without this. A fixed synthetic value makes the deck deterministic.
export ASMDATE=01/01/26 ASMTIME=00.00

[ -x ./as370 ] || { echo "corpus: as370 not built (run make first)"; exit 2; }
[ -d "$LIBC370/maclib" ] || { echo "corpus: libc370 not found at $LIBC370 (set LIBC370=)"; exit 2; }

# sha256 helper -- Linux has sha256sum, macOS has shasum
if command -v sha256sum >/dev/null 2>&1; then sha() { sha256sum "$1" | awk '{print $1}'; }
else                                          sha() { shasum -a 256 "$1" | awk '{print $1}'; }
fi

# every committed .asm/.s under libc370 except the work-in-progress tree,
# printed as a path relative to $LIBC370, sorted for a stable manifest order
modules() {
    find "$LIBC370" \( -name '*.asm' -o -name '*.s' \) 2>/dev/null |
        grep -v '/wip/' | sed "s|^$LIBC370/||" | sort
}

if [ "$1" = "--generate" ]; then
    prior=0; [ -f "$MANIFEST" ] && prior=$(wc -l < "$MANIFEST" | tr -d ' ')
    : > "$MANIFEST"
    n=0; skipped=0
    for rel in $(modules); do
        if ./as370 "$LIBC370/$rel" $MAC -o "$TMP" >/dev/null 2>&1; then
            printf '%s  %s\n' "$(sha "$TMP")" "$rel" >> "$MANIFEST"
            n=$((n + 1))
        else
            skipped=$((skipped + 1))   # does not assemble on as370 today (pre-existing)
        fi
    done
    rm -f "$TMP"
    echo "corpus: manifest regenerated -- $n modules, $skipped non-assembling skipped (was $prior)"
    # a shrink means a change stopped some modules assembling and baked them out
    # of the manifest -- surface it so a silent coverage loss can't slip through
    if [ "$prior" -gt "$n" ]; then
        echo "corpus: WARNING -- manifest SHRANK from $prior to $n; $((prior - n)) module(s) stopped assembling"
    fi
    exit 0
fi

[ -f "$MANIFEST" ] || { echo "corpus: no manifest -- run check.sh --generate"; exit 2; }

fail=0; checked=0
while read -r want rel; do
    [ -n "$rel" ] || continue
    checked=$((checked + 1))
    if ! ./as370 "$LIBC370/$rel" $MAC -o "$TMP" >/dev/null 2>&1; then
        echo "corpus: $rel NO LONGER ASSEMBLES (was in the manifest)"; fail=1; continue
    fi
    got=$(sha "$TMP")
    [ "$got" = "$want" ] || { echo "corpus: $rel CHANGED ($got != $want)"; fail=1; }
done < "$MANIFEST"
rm -f "$TMP"

# Coverage: fail closed on drift. A non-wip module on disk that ASSEMBLES but is
# not in the manifest is uncovered -- without this the gate would certify a
# subset while reading as if it certified the corpus (the hollow-guard failure).
# A module that does not assemble (e.g. @@stow.s) is legitimately absent, so we
# only flag the ones that DO assemble; drift then forces a conscious --generate.
covered=$(awk '{print $2}' "$MANIFEST" | sort)
for rel in $(modules); do
    printf '%s\n' "$covered" | grep -qx "$rel" && continue        # in the manifest
    if ./as370 "$LIBC370/$rel" $MAC -o "$TMP" >/dev/null 2>&1; then
        echo "corpus: $rel ASSEMBLES but is absent from the manifest (coverage drift -- run --generate)"
        fail=1
    fi
done
rm -f "$TMP"

disk=$(modules | wc -l | tr -d ' ')
echo "corpus: manifest covers $checked modules; $disk non-wip modules on disk"
[ $fail = 0 ] && echo "corpus: all $checked libc370 modules byte-identical to manifest (no coverage drift)" \
             || echo "corpus: FAILURES"
exit $fail
