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
# Macro-library root (maclib + sysmac). These live in libc370 now; the default
# used to point at crent370, the frozen v1.x libc, which no longer needs to be
# checked out. Override with LIBC370=/path .
LIBC370=${LIBC370:-../../libc370}
fail=0

# --- case 1: tstlist -- general listing (ESD + SOURCE + RLD) ----------------
REF=tests/listref/ifox-listing-tstlist.txt
OUT=/tmp/as370-listref.$$
ASMDATE=06/18/26 ASMTIME=06.42 ./as370 tests/listref/tstlist.s \
    -I "$LIBC370/maclib" -I "$LIBC370/sysmac" -a="$OUT" >/dev/null 2>&1 \
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

# --- case 3: reloc_addr -- issue #21 (IFO209, addressability) ----------------
# A relocatable implicit-base operand with no covering USING is IFO209 (severity
# 8): IFOX zeroes the instruction AND sets ADDR to 0 (unlike IFO228, which keeps
# the symbol value). This pins the zeroed object + ADDR-0 column against real
# IFOX00 (JOB00233). The comparison covers the eight L instructions and LABX;
# it stops at LTORG -- as370's -a mis-renders the LTORG LOC and literal-pool
# statement numbers (#28), and the DSECT tail hits #24. Both are listing-only
# (the object deck's pool alignment and literal offsets are byte-identical).
REF3=tests/listref/ifox-listing-reloc-addr.txt
OUT3=/tmp/as370-listref-addr.$$
ASMDATE=07/18/26 ASMTIME=03.11 ./as370 tests/reloc_addr.s -a="$OUT3" >/dev/null 2>&1
python3 - "$REF3" "$OUT3" <<'PY'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "LTORG" in l:                   break      # #28 (LTORG/literal) + #24 (DSECT tail) below
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
[ $? = 0 ] && echo "listref reloc_addr: IFO209 lines column-exact to IFOX00 (object zeroed, ADDR 0)" \
           || { echo "listref reloc_addr: MISMATCH"; fail=1; }
rm -f "$OUT3"


# --- case 4: multi_csect -- issue #70 (per-section ESD lengths) --------------
# The ESD section of the -a listing used to take its LENGTH column from modlen
# for the first section and print a hard zero for every other -- right only
# while a module has one section, which the three references above all are, so
# nothing caught it. This is the first multi-section listing reference in the
# tree; IFOX00 says FIRST 0x10, SECOND 4, THIRD 4, and the object deck has said
# so since #61.
#
# The comparison stops at THIRD, and each of the three reasons is a listing-only
# defect with its own issue -- the object deck for this module is byte-identical
# throughout:
#   THIRD CSECT   LOC printed before the origin is rounded up to a doubleword,
#                 the same pre-alignment-LOC defect as #28
#   MYDS DSECT    DSECT body rendered with the control section's counter and its
#                 object bytes -- #24
#   END ENT2      IFOX prints the entry point's address in the LOC column
#
# IFOX flags one statement, IFO158 for the deliberate DSECT-adcon control (#72),
# so its listing carries an *** ERROR *** marker; norm() drops those from both
# sides, as for the other error cases here.
REF4=tests/listref/ifox-listing-multi-csect.txt
OUT4=/tmp/as370-listref-mc.$$
./as370 tests/multi_csect.s -a="$OUT4" >/dev/null 2>&1
python3 - "$REF4" "$OUT4" <<'PY'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "THIRD    CSECT" in l:          break      # #28 / #24 / END LOC below
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
[ $? = 0 ] && echo "listref multi_csect: per-section ESD lengths column-exact to IFOX00" \
           || { echo "listref multi_csect: MISMATCH"; fail=1; }
rm -f "$OUT4"

exit $fail
