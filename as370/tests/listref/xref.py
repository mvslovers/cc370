#!/usr/bin/env python3
"""The -a CROSS-REFERENCE and LITERAL CROSS-REFERENCE pages (#538) against every
IFOX00 listing in this directory whose source is tests/<name>.s.

Each reference was captured with XREF(FULL), so each one carries the pages,
and nobody has to curate a case list: a new reference joins this gate the day
it is committed. One named ifox-listing-<name>-short.txt was captured with
XREF(SHORT) (capture.py --xref short) and is compared against --xref=short.

A cross-reference prints statement numbers, and a statement number is a
property of the SOURCE page -- an assembly whose source listing numbers a
statement differently (a macro definition IFOX lists and as370 does not, an
unsupported directive) prints a different number in the cross-reference too,
although nothing about the cross-reference is wrong. So a case passes either

  exact       the pages are identical, or
  renumbered  they are identical once as370's statement numbers are mapped onto
              IFOX00's by aligning the two SOURCE pages statement by statement.

Everything else must be in KNOWN with the issue that explains it, and an entry
in KNOWN that stops differing fails too: the list must not outlive its reasons.

usage: xref.py [-v] [name ...]       (run from the as370 directory)
"""
import difflib, glob, os, re, subprocess, sys, tempfile

# name -> why its cross-reference differs. Every one is a difference in what
# was ASSEMBLED, which the cross-reference reports faithfully.
KNOWN = {
    "equparen":  "F7 EQU ( S1+4): IFOX00 stops at the blank (IFO234) and gives 0, "
                 "as370 evaluates past it -- the message gap equparen.s records",
    "titlenamed": "the TITLE name (deck id) is not printed in columns 1-8 of a "
                  "page heading, on any page; IFO104 itself is #530",
    "xfdirect":  "#532-#535: OPSYN, AIFB/AGOB, ICTL and PUNCH, so the SOURCE "
                 "page numbers its macro definition differently",
}

here = os.path.dirname(os.path.abspath(__file__))
tests = os.path.dirname(here)
as370 = os.path.join(os.path.dirname(tests), "as370")
libc = os.environ.get("LIBC370", os.path.join(os.path.dirname(tests), "../../libc370"))
verbose = "-v" in sys.argv
only = [a for a in sys.argv[1:] if a != "-v"]


def xref_pages(lines):
    """The two cross-reference pages: headings kept with the page number and
    the identity block masked, blank lines dropped."""
    out, on = [], False
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if re.search(r"CROSS-REFERENCE +PAGE", l): on = True
        elif "DIAGNOSTICS AND STATISTICS" in l: on = False
        if not on or not l: continue
        if l.startswith("SYMBOL    LEN"): l = l[:90].rstrip()
        out.append(re.sub(r"PAGE +\d+$", "PAGE", l))
    return out


def statements(lines):
    """(statement number, source text) for every numbered SOURCE line."""
    out = []
    for l in lines:
        l = l.replace("\f", "").rstrip()
        if re.search(r"RELOCATION DICTIONARY|CROSS-REFERENCE", l): break
        n = l[33:39].strip()
        if n.isdigit(): out.append((int(n), l[40:]))
    return out


def renumber(ref, mine, pages):
    """as370's statement numbers in `pages', mapped onto IFOX00's."""
    a, b = statements(ref), statements(mine)
    sm = difflib.SequenceMatcher(None, [t for _, t in b], [t for _, t in a], autojunk=False)
    mp = {}
    for blk in sm.get_matching_blocks():
        for k in range(blk.size): mp[b[blk.a + k][0]] = a[blk.b + k][0]
    off = 0
    for n, _ in b:                       # an unmatched statement keeps its neighbour's offset
        if n in mp: off = mp[n] - n
        else: mp[n] = n + off
    def fix(l):
        if l.startswith("SYMBOL") or "CROSS-REFERENCE" in l: return l
        return l[:24] + re.sub(r"\b(\d{5})\b", lambda m: "%05d" % mp.get(int(m.group(1)), 0), l[24:])
    return [fix(l) for l in pages]


exact = renum = 0
bad, stale, known = [], [], []
for ref in sorted(glob.glob(os.path.join(here, "ifox-listing-*.txt"))):
    name = os.path.basename(ref)[len("ifox-listing-"):-4]
    short = name.endswith("-short")       # captured with XREF(SHORT): as370 --xref=short
    src = os.path.join(tests, (name[:-6] if short else name) + ".s")
    if not os.path.exists(src) or (only and name not in only): continue
    R = open(ref, encoding="latin-1").read().split("\n")
    m = re.search(r"ASM 0201 (\d\d\.\d\d) (\d\d/\d\d/\d\d)", "\n".join(R))
    fd, out = tempfile.mkstemp(); os.close(fd)
    cmd = [as370, src, "-a=" + out, "-o", os.devnull] + (["--xref=short"] if short else [])
    if os.path.isdir(os.path.join(libc, "maclib")):
        cmd += ["-I", os.path.join(libc, "maclib"), "-I", os.path.join(libc, "sysmac")]
    subprocess.run(cmd, capture_output=True, env=dict(os.environ, ASMTIME=m.group(1), ASMDATE=m.group(2)))
    M = open(out, encoding="latin-1").read().split("\n"); os.unlink(out)
    r, mm = xref_pages(R), xref_pages(M)
    if r == mm: ok = "exact"
    elif r == renumber(R, M, mm): ok = "renumbered"
    else: ok = None
    if name in KNOWN:
        (stale if ok else known).append(name)
        continue
    if ok == "exact": exact += 1
    elif ok: renum += 1
    else:
        bad.append(name)
        if verbose:
            for d in difflib.unified_diff(r, renumber(R, M, mm), "ifox", "as370", n=0, lineterm=""): print("   ", d)
print(f"listref xref: {exact} exact, {renum} identical after renumbering, "
      f"{len(known)} known divergences ({', '.join(known)})")
for n in bad: print(f"listref xref: {n}: DIFFERS")
for n in stale: print(f"listref xref: {n}: in KNOWN but no longer differs -- remove it ({KNOWN[n]})")
sys.exit(1 if bad or stale else 0)
