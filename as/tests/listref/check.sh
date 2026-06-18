#!/bin/sh
# Verify the as370 -a assembler listing (ESD + SOURCE + RLD sections) is
# column-exact to the IFOX00 reference for tests/listref/tstlist.s.
#
# Two documented exceptions are tolerated:
#   1. The page-header identity block (cols 90+ on the column-header lines) is
#      as370's own translator id, not IFOX's -- by design (see README.md).
#   2. IFOX's inline `*** ERROR ***` reentrancy diagnostic (IFO229) is a
#      diagnostics feature as370 does not implement.
# The XREF / LITERAL XREF / DIAGNOSTICS pages are likewise not produced yet and
# are excluded from the comparison.
cd "$(dirname "$0")/../.." || exit 2
CRENT=${CRENT:-../../crent370}
REF=tests/listref/ifox-listing-tstlist.txt
OUT=/tmp/as370-listref.$$
# the reference was assembled with this date/time; reproduce it so the header
# (and any &SYSDATE/&SYSTIME) line up
ASMDATE=06/18/26 ASMTIME=06.42 ./as370 tests/listref/tstlist.s \
    -I "$CRENT/maclib" -I "$CRENT/sysmac" -a="$OUT" >/dev/null 2>&1 \
    || { echo "listref: ASSEMBLE FAILED"; exit 1; }
python3 - "$REF" "$OUT" <<'PY'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
# keep only the sections as370 produces (ESD, source, RLD); stop at CROSS-REFERENCE
cut = next((i for i, l in enumerate(ref) if "CROSS-REFERENCE" in l), len(ref))
ref = ref[:cut]
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")   # column-header lines carry the identity block
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if l == "":                       continue
        if l.strip() == "*** ERROR ***":  continue   # IFOX-only diagnostic
        out.append(l)
    return out
R, M = norm(ref), norm(mine)
ok = True
for i in range(max(len(R), len(M))):
    r = R[i] if i < len(R) else "<none>"
    m = M[i] if i < len(M) else "<none>"
    hdr = any(r.startswith(p) for p in HDR)
    rc, mc = (r[:90], m[:90]) if hdr else (r, m)     # mask the identity block on header lines
    if rc != mc:
        ok = False
        print(f"DIFF line {i}:\n  ref |{r}|\n  mine|{m}|")
sys.exit(0 if ok else 1)
PY
rc=$?
rm -f "$OUT"
[ $rc = 0 ] && echo "listref: ESD + SOURCE + RLD column-exact to IFOX00" || echo "listref: MISMATCH"
exit $rc
