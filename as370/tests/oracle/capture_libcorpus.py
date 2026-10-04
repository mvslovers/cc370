#!/usr/bin/env python3
"""IFOX00 reference decks for the frozen libc370 corpus (cc370#23).

Inputs are as370/tests/libcorpus/: manifest.tsv names every module as Lnnnn
with its path under src/, and maclib/, sysmac/ and ccmacros/ are the macro
libraries the host assembles them with (-I maclib -I sysmac, then cc370's own
macros/) -- frozen copies, so the two sides cannot drift.

On the oracle (MVSTK5-REF, the .env cc370 uses):
  1. the three macro libraries are created as PDSs HERC01.CC370.C23.* and
     every member is written BINARY, converted here: read the way as370 reads
     a source (valid UTF-8 as UTF-8, anything else as Latin-1), encoded CP037
     -- Python's cp037 equals as370's table on all 191 printable Latin-1
     characters -- and padded to 80; each member is read back and compared.
     No RECEIVE is needed on the oracle, and no text conversion of mvsMF's
     sits between the macro and the assembler;
  2. the modules are assembled in jobs of up to STEPS steps, each source
     in-stream as capture.py sends it, PARM as capture.py uses, SYSLIB the
     three libraries in the host's order, SYSPRINT DUMMY, and SYSPUNCH
     appended (DISP=MOD) to one sequential data set per job;
  3. each job's data set is read back binary and cut at the END cards; a cut
     deck is accepted only if its ESD names equal as370's for that module,
     so a module that punched nothing cannot shift the ones after it;
  4. every data set this run created is deleted (the macro libraries only
     after a full run, so --only-job can be repeated).

The snapshot either side of the batch is the caller's (macrosnap.py), as for
any oracle job.  Without --submit only the JCL is built and gated.

  python3 as370/tests/oracle/capture_libcorpus.py            # build + gate
  AS370_MVS_ENV=.env python3 as370/tests/oracle/capture_libcorpus.py --submit
"""
import argparse
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
CORPUS = os.path.join(ROOT, "as370", "tests", "libcorpus")
AS370 = os.path.join(ROOT, "as370", "as370")
XMIT370 = os.path.join(ROOT, "xmit370", "xmit370")
HLQ = "HERC01.CC370.C23"
LIBS = [("maclib", "MACLIB"), ("sysmac", "SYSMAC"), ("ccmacros", "CCMACROS")]
STEPS = 60
MAXJCL = 160000
TMP = "UNIT=SYSDA,SPACE=(CYL,(1,1))"


def manifest():
    rows = []
    for line in open(os.path.join(CORPUS, "manifest.tsv")):
        if line.startswith("#") or not line.strip():
            continue
        mem, path, sha = line.rstrip("\n").split("\t")
        rows.append((mem, path))
    return rows


def ebc_cards(deck):
    return [deck[i:i + 80] for i in range(0, len(deck), 80)]


def esd_names(deck):
    """Names of the ESD items of an object deck, in order."""
    names = []
    for c in ebc_cards(deck):
        if c[1:4] != b"\xc5\xe2\xc4":          # 'ESD'
            continue
        n = int.from_bytes(c[10:12], "big")
        for k in range(0, n, 16):
            e = c[16 + k:32 + k]
            if e[8] == 0x01:                  # LD items carry no ESDID; keep them too
                pass
            names.append((e[:8].decode("cp037").rstrip(), e[8]))
    return names


def split_decks(data):
    """Cut a concatenation of object decks after each END card."""
    decks, cur = [], []
    for c in ebc_cards(data):
        cur.append(c)
        if c[1:4] == b"\xc5\xd5\xc4":         # 'END'
            decks.append(b"".join(cur))
            cur = []
    return decks, b"".join(cur)


def as370_deck(path):
    out = os.path.join("/tmp", f"_c23_{os.getpid()}.obj")
    subprocess.run([AS370, path, "-I", os.path.join(CORPUS, "maclib"),
                    "-I", os.path.join(CORPUS, "sysmac"), "-I", os.path.join(CORPUS, "ccmacros"),
                    "-o", out], capture_output=True)
    try:
        return open(out, "rb").read()
    except OSError:
        return b""
    finally:
        if os.path.exists(out):
            os.remove(out)


def build_jobs(rows, env):
    jobs = []
    groups, cur, size = [], [], 0
    for mem, path in rows:                    # at most STEPS steps and MAXJCL bytes a job
        n = os.path.getsize(os.path.join(CORPUS, "src", path)) + 900
        if cur and (len(cur) >= STEPS or size + n > MAXJCL):
            groups.append(cur); cur, size = [], 0
        cur.append((mem, path)); size += n
    if cur:
        groups.append(cur)
    for k, part in enumerate(groups, 1):
        obj = f"{HLQ}.OBJ{k:02d}"
        lines = [f"//C23ASM{k:02d} JOB (ACCT),'C23 ORACLE {k}',CLASS={env.get('MBT_JES_JOBCLASS', 'A')},",
                 f"//             MSGCLASS={env.get('MBT_JES_MSGCLASS', 'A')},MSGLEVEL=(1,1)",
                 "//DEL      EXEC PGM=IEFBR14",
                 f"//OLD      DD DSN={obj},DISP=(MOD,DELETE,DELETE),",
                 "//             UNIT=SYSDA,SPACE=(TRK,(1,1))",
                 "//NEW      EXEC PGM=IEFBR14",
                 f"//OBJ      DD DSN={obj},DISP=(NEW,CATLG,DELETE),",
                 "//             UNIT=SYSDA,SPACE=(TRK,(90,30),RLSE),",
                 "//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=800)"]
        for n, (mem, path) in enumerate(part, 1):
            src = open(os.path.join(CORPUS, "src", path), encoding="ascii").read().splitlines()
            lines += [f"//S{n:03d}     EXEC PGM=IFOX00,COND=EVEN,",
                      "//          PARM='DECK,LIST,NOLOAD,XREF(FULL),RENT'"]
            for i, (lib, name) in enumerate(LIBS):
                lines.append(f"//{'SYSLIB' if i == 0 else '':<8} DD DSN={HLQ}.{name},DISP=SHR")
            lines += [f"//SYSUT1   DD {TMP}", f"//SYSUT2   DD {TMP}", f"//SYSUT3   DD {TMP}",
                      "//SYSPRINT DD DUMMY", "//SYSGO    DD DUMMY",
                      f"//SYSPUNCH DD DSN={obj},DISP=MOD", "//SYSIN    DD *"]
            lines += src + ["/*"]
        lines.append("//")
        jobs.append((k, obj, part, "\n".join(lines) + "\n"))
    return jobs


def gate(jobs):
    bad = 0
    for k, obj, part, jcl in jobs:
        for i, l in enumerate(jcl.splitlines(), 1):
            if l.startswith("//") and len(l) > 71:
                print(f"job {k}: JCL line {i} past column 71: {l[:40]}...", file=sys.stderr)
                bad += 1
    return bad == 0


def load_env(path):
    env = {}
    for line in open(path):
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env[k.strip()] = v.strip()
    return env


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--submit", action="store_true")
    ap.add_argument("--out", default=os.path.join(CORPUS, "ifox"))
    ap.add_argument("--work", default="/tmp/c23work")
    ap.add_argument("--only-job", type=int, default=0, help="run this job number only")
    args = ap.parse_args()
    envp = os.environ.get("AS370_MVS_ENV", os.path.join(ROOT, ".env"))
    env = load_env(envp) if os.path.exists(envp) else {}
    rows = manifest()
    jobs = build_jobs(rows, env)
    print(f"{len(rows)} modules in {len(jobs)} jobs; largest JCL {max(len(j[3]) for j in jobs)} bytes")
    if not gate(jobs):
        return 1
    if not args.submit:
        return 0

    sys.path.insert(0, os.path.expanduser("~/repos/mvs/mbt/scripts"))
    from mbt.mvsmf import MvsMFClient
    assert env.get("MBT_MVS_PORT") == "8084", "the oracle is MVSTK5-REF, port 8084"
    c = MvsMFClient(env["MBT_MVS_HOST"], int(env["MBT_MVS_PORT"]), env["MBT_MVS_USER"], env["MBT_MVS_PASS"])
    os.makedirs(args.work, exist_ok=True)
    os.makedirs(args.out, exist_ok=True)
    created = []

    macro_libs = [f"{HLQ}.{name}" for _, name in LIBS]
    if not args.only_job or args.only_job == 1:
        # 1. macro libraries, member by member, binary
        for lib, name in LIBS:
            ds = f"{HLQ}.{name}"
            files = sorted(os.listdir(os.path.join(CORPUS, lib)))
            if c.dataset_exists(ds):
                c.delete_dataset(ds)
            c.create_dataset(ds, "PO", "FB", 80, 3120, ["TRK", 30, 15, len(files) // 5 + 5])
            for f in files:
                raw = open(os.path.join(CORPUS, lib, f), "rb").read()
                try:
                    text = raw.decode("utf-8")
                except UnicodeDecodeError:
                    text = raw.decode("latin-1")
                recs = b"".join(l.rstrip(" ").encode("cp037").ljust(80, b"\x40")
                                for l in text.splitlines())
                mem = os.path.splitext(f)[0].upper()
                c._request("PUT", f"/restfiles/ds/{ds}({mem})", recs,
                           content_type="application/octet-stream", accept="*/*",
                           extra_headers={"X-IBM-Data-Type": "binary"})
                back = c._request("GET", f"/restfiles/ds/{ds}({mem})", accept="application/octet-stream",
                                  extra_headers={"X-IBM-Data-Type": "binary"})
                if back.rstrip(b"\x40") != recs.rstrip(b"\x40"):
                    sys.exit(f"{ds}({mem}): read back differs from what was written")
            print(f"macros: {ds} {len(files)} members written and read back")

    # 2.-3. assemble, read back, cut
    accepted = rejected = 0
    for k, obj, part, jcl in jobs:
        if args.only_job and k != args.only_job:
            continue
        r = c.submit_jcl(jcl, wait=True, timeout=1800)
        print(f"job {k}: {r.jobname} {r.jobid} status={r.status} rc={r.rc} ({len(part)} modules)")
        open(os.path.join(args.work, f"job{k:02d}-{r.jobid}.txt"), "w").write(r.spool)
        rcs = [l for l in r.spool.splitlines() if "IEF142I" in l and " S" in l]
        open(os.path.join(args.work, f"job{k:02d}-rc.txt"), "w").write("\n".join(rcs) + "\n")
        data = c._request("GET", f"/restfiles/ds/{obj}", accept="application/octet-stream",
                          extra_headers={"X-IBM-Data-Type": "binary"})
        created.append(obj)
        decks, rest = split_decks(data)
        print(f"   {len(decks)} decks read back for {len(part)} modules" + (f", {len(rest)} trailing bytes" if rest else ""))
        di = 0
        for mem, path in part:
            mine = as370_deck(os.path.join(CORPUS, "src", path))
            want = esd_names(mine)
            if di < len(decks) and esd_names(decks[di]) == want:
                open(os.path.join(args.out, f"{mem}.obj"), "wb").write(decks[di])
                accepted += 1
                di += 1
            else:
                rejected += 1
                print(f"   {mem} {path}: no deck with as370's ESD names at position {di} -- not recorded")
        time.sleep(2)

    # 4. clean up
    if not args.only_job:
        created += macro_libs
    for ds in created:
        try:
            c.delete_dataset(ds)
        except Exception as exc:                      # noqa: BLE001
            print(f"could not delete {ds}: {exc}", file=sys.stderr)
    print(f"accepted {accepted}, not recorded {rejected}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
