#!/bin/sh
# Verify the as370 -a assembler listing (ESD + SOURCE + RLD sections, and the
# CROSS-REFERENCE pages) is column-exact to the IFOX00 reference.
#
# Two documented exceptions are tolerated on every case:
#   1. The page-header identity block (cols 90+ on the column-header lines) is
#      as370's own translator id, not IFOX's -- by design (see README.md).
#   2. IFOX's inline `*** ERROR ***` diagnostic marker is not implemented.
# The DIAGNOSTICS AND STATISTICS page is not produced yet and is excluded. The
# cross-reference pages are compared in case 1 and, across every reference in
# this directory, by xref.py (case 8).
cd "$(dirname "$0")/../.." || exit 2
# Macro-library root (maclib + sysmac). These live in libc370 now; the default
# used to point at crent370, the frozen v1.x libc, which no longer needs to be
# checked out. Override with LIBC370=/path .
LIBC370=${LIBC370:-../../libc370}
fail=0

# Case 1 assembles a macro-library module and is the only case that needs the
# libc370 checkout; the other four are self-contained. It SKIPS rather than
# fails where libc370 is absent, so this suite can run in CI, which has no
# ecosystem checkout beside it. Skipping case 1 costs the NOMLOGIC guard -- it
# is the case that proves conditional statements inside a macro stay unlisted --
# so a local run with libc370 present remains the real gate.
have_libc=1
[ -d "$LIBC370/maclib" ] && [ -d "$LIBC370/sysmac" ] || have_libc=0

# --- case 1: tstlist -- general listing (ESD + SOURCE + RLD + XREF) ---------
if [ $have_libc = 0 ]; then
    echo "listref tstlist: SKIPPED (needs the libc370 checkout; set LIBC370=<path>)"
else
REF=tests/listref/ifox-listing-tstlist.txt
OUT=/tmp/as370-listref.$$
ASMDATE=06/18/26 ASMTIME=06.42 ./as370 tests/listref/tstlist.s \
    -I "$LIBC370/maclib" -I "$LIBC370/sysmac" -a="$OUT" >/dev/null 2>&1 \
    || { echo "listref tstlist: ASSEMBLE FAILED"; fail=1; }
python3 - "$REF" "$OUT" <<'PY'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
# keep only the sections as370 produces (ESD, source, RLD, XREF); stop at DIAGNOSTICS
cut = next((i for i, l in enumerate(ref) if "DIAGNOSTICS AND STATISTICS" in l), len(ref))
ref = ref[:cut]
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID", "SYMBOL    LEN")   # column-header lines carry the identity block
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
[ $? = 0 ] && echo "listref tstlist: ESD + SOURCE + RLD + XREF column-exact to IFOX00" \
           || { echo "listref tstlist: MISMATCH"; fail=1; }
rm -f "$OUT"
fi

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
# IFOX00 (JOB00233). The comparison covers the eight L instructions, LABX, and
# the LTORG with its pool -- the LTORG at its doubleword-aligned LOC and the
# literals numbered right behind it, both wrong in as370 before #28. It
# stops at the DSECT tail, which hits #24 (listing-only: the object deck is
# byte-identical).
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
        if "MYDS     DSECT" in l:          break      # #24 (DSECT tail) below
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
[ $? = 0 ] && echo "listref reloc_addr: IFO209 lines + LTORG pool column-exact to IFOX00 (object zeroed, ADDR 0)" \
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

# --- case 5: setc_open -- issue #141 (substitution in open code) -------------
# The listing half of #141, and the half that is easy to get half right. Three
# things have to hold at once and each was wrong before:
#
#   the CONDITIONAL statements are listed. IFOX00 prints LCLC and both SETC
#   cards -- ALOGIC is on by default, as the fixture's own OPTIONS line says --
#   where as370 swallowed them, so everything after them was numbered three low.
#
#   a substituted model statement is listed TWICE: the source card, print-only
#   with no location, then the generated card carrying the object code and the
#   '+'. Statements 23 and 24+.
#
#   the values are IFOX's. &A is null because 'AB'(5,4) starts past the end --
#   that is the IFO117 the assembly returns 8 for -- and &B is BCD.
#
# It is also the guard on the OTHER half of the listing rule: NOMLOGIC is the
# default and IFOX00 lists none of the ~70 conditional statements inside
# tstlist's SAVE and RETURN. Case 1 above fails loudly if this listing gate ever
# stops being restricted to generation level 0.
#
# IFOX flags the SETC, so its listing carries an *** ERROR *** marker; norm()
# drops those from both sides as in the other error cases here.
REF5=tests/listref/ifox-listing-setc_open.txt
OUT5=/tmp/as370-listref-so.$$
ASMDATE=09/06/26 ASMTIME=11.35 ./as370 tests/setc_open.s -a="$OUT5" >/dev/null 2>&1
python3 - "$REF5" "$OUT5" <<'PYX'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "CROSS-REFERENCE" in l:         break      # as370 emits no XREF page
        if l == "":                        continue
        if l.strip() == "*** ERROR ***":   continue   # IFOX-only diagnostic marker
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
PYX
[ $? = 0 ] && echo "listref setc_open: open-code substitution column-exact to IFOX00" \
           || { echo "listref setc_open: MISMATCH"; fail=1; }
rm -f "$OUT5"

# --- case 6: equlist -- EQU / ORG / DSECT in the LOC and ADDR2 columns -------
# The first listref case with an EQU in it, which is how #226 went unnoticed:
# the suite has been column-exact since it was written and simply never saw one.
#
# Two lines are EXPECTED to differ and are asserted rather than tolerated -- ORG
# and DSECT list the incoming location counter where IFOX00 lists their own
# (#227). The check fails if either stops differing, so fixing #227 breaks this
# case loudly and asks for the expectation to be updated. That is the point:
# a divergence nobody has to look at is a divergence nobody will fix.
REF6=tests/listref/ifox-listing-equlist.txt
OUT6=/tmp/as370-listref-eq.$$
ASMDATE=09/07/26 ASMTIME=12.00 ./as370 tests/listref/equlist.s -a="$OUT6" >/dev/null 2>&1
python3 - "$REF6" "$OUT6" <<'PYE'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
KNOWN = ()                        # cc370#227 fixed; ORG/DSECT now match here too
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "CROSS-REFERENCE" in l:         break
        if l == "":                        continue
        if l.strip() == "*** ERROR ***":   continue
        out.append(l)
    return out
R, M = norm(ref), norm(mine)
ok, seen = True, set()
for i in range(max(len(R), len(M))):
    r = R[i] if i < len(R) else "<none>"
    m = M[i] if i < len(M) else "<none>"
    hdr = any(r.startswith(p) for p in HDR)
    rc, mc = (r[:90], m[:90]) if hdr else (r, m)
    known = next((k for k in KNOWN if f"   {k}" in r or f" {k}" == r[-len(k)-1:]), None)
    if known and rc != mc:
        seen.add(known)                    # the #227 divergence, expected
        continue
    if rc != mc:
        ok = False
        print(f"DIFF line {i}:\n  ref |{r}|\n  mine|{m}|")
missing = [k for k in KNOWN if k not in seen]
if missing:
    ok = False
    print(f"#227 no longer diverges on {missing} -- fixed? update this case")
sys.exit(0 if ok else 1)
PYE
[ $? = 0 ] && echo "listref equlist: EQU value in ADDR2 column-exact to IFOX00" \
           || { echo "listref equlist: MISMATCH"; fail=1; }
rm -f "$OUT6"

# --- case 7: orglist -- every statement that moves or replaces the counter ---
# ORG (three forms, and one inside a DSECT), a NEW control section, a RESUMED
# one, and a DSECT opened twice. The resumed cases are the point: without them
# "the section's origin" and "the section's own counter" give the same answer.
#
# CM1 is asserted to DIVERGE: as370 has no COM support at all -- no ESD entry,
# no counter from zero (#229) -- and the three cards after it inherit that. The
# case fails if it stops diverging, which is how #229 gets its gate for free.
REF7=tests/listref/ifox-listing-orglist.txt
OUT7=/tmp/as370-listref-og.$$
ASMDATE=09/07/26 ASMTIME=12.00 ./as370 tests/listref/orglist.s -a="$OUT7" >/dev/null 2>&1
python3 - "$REF7" "$OUT7" <<'PYO'
import sys
ref  = open(sys.argv[1]).read().split("\n")
mine = open(sys.argv[2]).read().split("\n")
HDR = ("SYMBOL   TYPE", "  LOC  OBJECT", "POS.ID")
def norm(lines):
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if "CROSS-REFERENCE" in l:         break
        if l == "":                        continue
        if l.strip() == "*** ERROR ***":   continue
        out.append(l)
    return out
R, M = norm(ref), norm(mine)
# Drop the CM1 ESD line from the reference rather than skipping it in place:
# leaving it in shifts every later line by one, and every comparison after it
# then reports a difference that is really an alignment artefact.
cm_esd = [l for l in R if " CM  " in l and not l[40:].startswith("CM1")]
R = [l for l in R if l not in cm_esd]
# Everything from the COM statement onward is in #229's shadow: as370 has no
# COM support, so that section's counter and every counter after it are wrong.
# Keyed on the source text, not a statement number -- the comment block at the
# head of the fixture would renumber every case that used one.
def com_at(lines):
    for i, l in enumerate(lines):
        if l[40:].startswith("CM1      COM"): return i
    return len(lines)
cut = min(com_at(R), com_at(M))
ok, seen229 = True, False
if cm_esd and not any(" CM  " in l and "COM" not in l[40:] for l in M):
    seen229 = True                              # the missing CM1 ESD entry
for i in range(max(len(R), len(M))):
    r = R[i] if i < len(R) else "<none>"
    m = M[i] if i < len(M) else "<none>"
    if any(r.startswith(p) for p in HDR):
        if r[:90] != m[:90]: ok = False; print(f"DIFF hdr {i}:\n  ref |{r}|\n  mine|{m}|")
        continue
    if i >= cut:
        if r != m: seen229 = True
        continue
    if r != m:
        ok = False
        print(f"DIFF line {i}:\n  ref |{r}|\n  mine|{m}|")
if not seen229:
    ok = False
    print("#229 no longer diverges -- COM implemented? update this case")
sys.exit(0 if ok else 1)
PYO
[ $? = 0 ] && echo "listref orglist: ORG/CSECT/DSECT counters column-exact to IFOX00 (COM diverges, #229)" \
           || { echo "listref orglist: MISMATCH"; fail=1; }
rm -f "$OUT7"

# --- case 9: AIF/AGO of open code, and a sequence symbol in the name field -- #607
# IFOX00 lists an AIF or AGO of open code and numbers it (ALOGIC), and prints a
# card whose name field is a sequence symbol as written -- `.A       DC    C'Y1''.
# as370 dropped the first and re-rendered the second as `DC C'Y1'', so collate
# ended at statement 35 where IFOX00 says 42. Case 8 could not see it: it maps
# statement numbers across. Both SOURCE pages are compared line for line --
# page headings and IFOX's *** ERROR *** markers aside. aifcond's AIFs are
# continued, and until #609 as370 listed a continued open-code statement as one
# joined line, so aifcond was compared on its statement numbers only.
# Both have no macro definition; the other three fixtures with open-code AIF do,
# and their definitions are not listed (#150).
for T9 in collate aifcond; do
OUT9=/tmp/as370-listref-aif.$$
./as370 tests/$T9.s -a="$OUT9" >/dev/null 2>&1
python3 - tests/listref/ifox-listing-$T9.txt "$OUT9" "$T9" <<'PYX'
import sys, re
def src(path):
    out, on = [], False
    for l in open(path, encoding="latin-1").read().split("\n"):
        l = l.replace("\f", "").rstrip()
        if "SOURCE STATEMENT" in l: on = True; continue
        if not on: continue
        if re.search(r"(CROSS-REFERENCE|RELOCATION DICTIONARY|DIAGNOSTICS AND)", l): break
        if l == "" or l.strip() == "*** ERROR ***" or re.search(r"PAGE +\d+$", l): continue
        out.append(l)
    return out
R, M = src(sys.argv[1]), src(sys.argv[2])
bad = [(i, R[i] if i < len(R) else "<none>", M[i] if i < len(M) else "<none>")
       for i in range(max(len(R), len(M))) if (R[i] if i < len(R) else None) != (M[i] if i < len(M) else None)]
for i, r, m in bad[:6]: print(f"DIFF line {i}:\n  ref |{r}|\n  mine|{m}|")
sys.exit(1 if bad or not R else 0)
PYX
[ $? = 0 ] && echo "listref $T9: SOURCE page matches IFOX00 (open-code AIF/AGO listed and numbered, sequence symbols kept)" \
           || { echo "listref $T9: MISMATCH"; fail=1; }
rm -f "$OUT9"
done

# --- case 8: the cross-reference pages of every reference here -- #538 ------
# Every listing in this directory was captured with XREF(FULL), so each carries
# a CROSS-REFERENCE page and most a LITERAL CROSS-REFERENCE: xref.py compares
# them all, maps statement numbers through the SOURCE page where that page
# numbers differently, and names the issue behind each case it lets differ.
python3 tests/listref/xref.py || fail=1

exit $fail
