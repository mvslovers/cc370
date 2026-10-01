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
# Both have no macro definition; fixtures that do are compared line for line
# by case 12 since #150 lists the definitions.
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

# --- case 10: END's LOC, across every reference here -- #619 --------------
# END naming an entry point lists that symbol's VALUE in LOC: `END T' is 000000
# where T opens the section, 000008 in usingparenpc, 000012 for multi-csect's
# `END ENT2'. Without an operand LOC is blank. as370 left it blank always. The
# END row is compared on LOC alone: its statement number still moves in the
# references case 12 does not hold.
python3 - "$LIBC370" "$have_libc" <<'PYE' || fail=1
import sys, re, glob, os, subprocess
inc = ["-I", sys.argv[1] + "/maclib", "-I", sys.argv[1] + "/sysmac"] if sys.argv[2] == "1" else []
endrow = lambda t: [l for l in t.split("\n") if re.match(r"^.{33} +[0-9]+[ +]+ +END\b", l)]
n, bad = 0, []
for ref in sorted(glob.glob("tests/listref/ifox-listing-*.txt")):
    t = ref.split("ifox-listing-")[1][:-4]
    src = next((x for x in ("tests/%s.s" % t, "tests/%s.s" % t.replace("-", "_"), "tests/listref/%s.s" % t) if os.path.exists(x)), None)
    R = endrow(open(ref, encoding="latin-1").read())
    if not src or not R: continue
    out = "/tmp/as370-listref-end.%d" % os.getpid()
    subprocess.run(["./as370", src] + inc + ["-a=" + out, "-o", "/dev/null"], capture_output=True)
    M = endrow(open(out, encoding="latin-1").read()) if os.path.exists(out) else []
    if os.path.exists(out): os.remove(out)
    n += 1
    if not M or M[-1][:6] != R[-1][:6]: bad.append((t, R[-1][:6], M[-1][:6] if M else "<none>"))
for t, r, m in bad[:6]: print("DIFF %s: ref |%s| mine |%s|" % (t, r, m))
print("listref endloc: END's LOC column-exact to IFOX00 in %d references" % n if not bad and n
      else "listref endloc: MISMATCH (%d of %d)" % (len(bad), n))
sys.exit(1 if bad or not n else 0)
PYE

# --- case 11: TITLE and EJECT, and the SOURCE page headings -- #603 --------
# Every TITLE and every EJECT starts a SOURCE page at once and is not listed;
# the TITLE's text heads every page from column 10 until the next one, '' and
# && printed once, at most 100 characters (more is IFO171, severity 4). The
# headings are compared here, which case 9 cannot do: it drops them.
# printgen/printerr add PRINT ON/OFF, GEN/NOGEN and PUSH/POP PRINT, and
# spacelist/spacelines SPACE (#623); sysparm_substr is #150's own fixture, an
# in-stream definition listed and numbered where it is written. All compare
# line for line, statement numbers included; printgen also holds NOMCALL, the
# call inside OUTER's expansion neither listed nor numbered (#626), and
# printerr an aligned DC listed at its own address (#627). Nothing is pinned any
# more; `known' is where a difference goes, with the issue that owns it, if one
# has to be tolerated again. Blank lines count: a SPACE is blank records, one
# per three lines, as spacelist and spacelines measured them.
for T11 in titlenamed titlelong titlepage titlegen printgen printerr spacelist spacelines sysparm_substr; do
OUT11=/tmp/as370-listref-title.$$
./as370 tests/$T11.s -a="$OUT11" >/dev/null 2>/tmp/as370-listref-title.err.$$
rc11=$?
python3 - tests/listref/ifox-listing-$T11.txt "$OUT11" "$T11" "$rc11" /tmp/as370-listref-title.err.$$ <<'PYT'
import sys, re, difflib
ref, mine, t, rc, err = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), sys.argv[5]
def src(path):
    out, on = [], False
    for l in open(path, encoding="latin-1").read().split("\n"):
        l = l.replace("\f", "").rstrip()
        if re.search(r"PAGE +\d+$", l):
            if re.search(r"(CROSS-REFERENCE|RELOCATION DICTIONARY|DIAGNOSTICS AND|EXTERNAL SYMBOL)", l):
                if on: break
                continue
            on = True; out.append("HEAD|" + l[:110].rstrip()); continue
        if not on or "SOURCE STATEMENT" in l or l.strip() == "*** ERROR ***": continue
        out.append(l)
    while out and out[-1] == "": out.pop()
    return out
R, M = src(ref), src(mine)
known = {   # what is still different, and whose it is
}
d = [x for x in difflib.unified_diff(R, M, lineterm="", n=0) if x[:1] in "+-" and x[:3] not in ("---", "+++")]
want = known.get(t, [])
ok = d == want and len(R) > 0
if t == "titlelong":   # IFO171 twice, rc 4 -- IFOX00 flags statements 7 and 9
    n171 = open(err).read().count("IFO171")
    if rc != 4 or n171 != 2: ok = False; print("titlelong: rc %d, %d x IFO171 (IFOX00: rc 4, 2)" % (rc, n171))
if t == "printerr" and rc != 8: ok = False; print("printerr: rc %d (IFOX00: 8)" % rc)
for x in d[:8]:
    if x not in want: print("  unexpected " + x[:110])
for x in want:
    if x not in d: print("  no longer differs -- update this case: " + x[:90])
print("listref %s: SOURCE page %s" % (t, "matches IFOX00" + (" (%d pinned)" % len(want) if want else "") if ok else "MISMATCH"))
sys.exit(0 if ok else 1)
PYT
[ $? = 0 ] || fail=1
rm -f "$OUT11" /tmp/as370-listref-title.err.$$
done

# --- case 12: every SOURCE page that matches IFOX00 keeps matching -- #150 --
# The SOURCE page of each reference named here is IFOX00's line for line:
# headings, statement numbers and blank lines; *** ERROR *** markers aside.
# Before #150 listed in-stream macro definitions, 63 of the 135 did; 95 do
# since #626 (NOMCALL) and #627 (alignment pads), plus tstlist, which needs
# the libc370 macros and is case 1's. A reference that starts matching belongs on this list; one that
# stops is a regression.
python3 - <<'PYS' || fail=1
import re, os, subprocess
NAMES = """
absrx absssub absusing actr adcon aifcond aliasext align amp_fold
amp_selfdef amp_subst attrapos_remark attrdup attre basereg basereg2 bitlen
blank_csect brmnem ccwstar cmprule collate contattr contparen csect_resume
csect_resume2 csect_resume3 dcattr dcvals dupfac emptydc emptyopnd endpool
endstop entryprobe entsd equfwd equlen equlist eququote equtype esdself
esdvsect fpopc genblank kwundef lblorg ldentry lenattr litdup litdupexpr
litlist litplusterm litpz litscale logop macbuf orglen parendepth pool
printerr printgen regexpr relocerr relop rldlen sconabs selfdup setc_len95
setc_open setc_substr setc_undef spacelines spacelist spmrr ssb1 stmtlen
subattr sublist substrcat syslist sysparm_substr tattr_expr tattr_literal
tattr_selfdef titlegen titlelong titlenamed titlepage usingexpr usingkey
usingmul var_opcode xfdirect xsectrel
""".split()
def src(path):
    out, on = [], False
    for l in open(path, encoding="latin-1").read().split("\n"):
        l = l.replace("\f", "").rstrip()
        if re.search(r"PAGE +\d+$", l):
            if re.search(r"(CROSS-REFERENCE|RELOCATION DICTIONARY|DIAGNOSTICS AND|EXTERNAL SYMBOL)", l):
                if on: break
                continue
            on = True; out.append("HEAD|" + l[:110].rstrip()); continue
        if not on or "SOURCE STATEMENT" in l or l.strip() == "*** ERROR ***": continue
        out.append(l)
    while out and out[-1] == "": out.pop()
    return out
bad = []
for t in NAMES:
    s = next(x for x in ("tests/%s.s" % t, "tests/listref/%s.s" % t) if os.path.exists(x))
    out = "/tmp/as370-listref-src.%d" % os.getpid()
    subprocess.run(["./as370", s, "-a=" + out, "-o", "/dev/null"], capture_output=True)
    if src(out) != src("tests/listref/ifox-listing-%s.txt" % t): bad.append(t)
    os.remove(out)
print("listref source: %d SOURCE pages line for line with IFOX00" % len(NAMES) if not bad
      else "listref source: MISMATCH in %s" % " ".join(bad))
raise SystemExit(1 if bad else 0)
PYS

# --- case 8: the cross-reference pages of every reference here -- #538 ------
# Every listing in this directory was captured with XREF(FULL), so each carries
# a CROSS-REFERENCE page and most a LITERAL CROSS-REFERENCE: xref.py compares
# them all, maps statement numbers through the SOURCE page where that page
# numbers differently, and names the issue behind each case it lets differ.
python3 tests/listref/xref.py || fail=1

exit $fail
