#!/bin/sh
# Verify the as370 -a assembler listing (ESD + SOURCE + RLD sections) is
# column-exact to the IFOX00 reference.
#
# Two documented exceptions are tolerated on every case:
#   1. The page-header identity block (cols 90+ on the column-header lines) is
#      as370's own translator id, not IFOX's -- by design (see README.md).
#   2. IFOX's inline `*** ERROR ***` diagnostic marker is not implemented.
# The XREF / LITERAL XREF / DIAGNOSTICS pages are likewise not produced yet and
# are excluded from the comparison.
cd "$(dirname "$0")/../.." || exit 2
CRENT=${CRENT:-../../crent370}
fail=0

# --- case 1: tstlist -- general listing (ESD + SOURCE + RLD) ----------------
REF=tests/listref/ifox-listing-tstlist.txt
OUT=/tmp/as370-listref.$$
ASMDATE=06/18/26 ASMTIME=06.42 ./as370 tests/listref/tstlist.s \
    -I "$CRENT/maclib" -I "$CRENT/sysmac" -a="$OUT" >/dev/null 2>&1 \
    || { echo "listref tstlist: ASSEMBLE FAILED"; fail=1; }
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
[ $? = 0 ] && echo "listref tstlist: ESD + SOURCE + RLD column-exact to IFOX00" \
           || { echo "listref tstlist: MISMATCH"; fail=1; }
rm -f "$OUT"

# --- case 2: reloc_disp -- issue #18 (IFO228, relocatable displacement) ------
# A machine instruction with a relocatable displacement and an explicit base is
# an IFO228 error (severity 8): IFOX zeroes the whole instruction but STILL
# prints the symbol's un-reduced value in ADDR1. This case pins that -- the
# zeroed object plus the preserved ADDR1 column -- for all five operand formats
# with a storage operand (RX/RS/SI/SS and the S format STCK/SPKA), against the
# real IFOX00 listing (assembled on MVS 3.8j, job IFOXTST/JOB00229). reloc_disp.s
# needs no macro library. Two categories of lines are excluded, each with a reason:
#   *** ERROR ***         IFOX inline marker (as370 reports IFO228 to stderr)
#   from `MYDS DSECT` on  DSECT-body DS listing rendering -- tracked in #24
REF2=tests/listref/ifox-listing-reloc.txt
OUT2=/tmp/as370-listref-reloc.$$
ASMDATE=07/17/26 ASMTIME=15.15 ./as370 tests/reloc_disp.s -a="$OUT2" >/dev/null 2>&1
python3 - "$REF2" "$OUT2" <<'PY'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "MYDS     DSECT" in l:          break      # #24: DSECT-body listing bug
        if l == "":                        continue
        if l.strip() == "*** ERROR ***":   continue   # IFOX-only diagnostic
        out.append(l)
    return out
R, M = norm(ref), norm(mine)
ok = True
for i in range(max(len(R), len(M))):
    r = R[i] if i < len(R) else "<none>"
    m = M[i] if i < len(M) else "<none>"
    hdr = any(r.startswith(p) for p in HDR)
    rc, mc = (r[:90], m[:90]) if hdr else (r, m)
    if rc != mc:
        ok = False
        print(f"DIFF line {i}:\n  ref |{r}|\n  mine|{m}|")
sys.exit(0 if ok else 1)
PY
[ $? = 0 ] && echo "listref reloc_disp: IFO228 lines column-exact to IFOX00 (object zeroed, ADDR1 kept)" \
           || { echo "listref reloc_disp: MISMATCH"; fail=1; }
rm -f "$OUT2"

exit $fail
