#!/usr/bin/env python3
"""Host-native build of httpd + mvsmf into MVS dataset HTTPD.LINKLIB2.

The whole chain runs on the host -- no IFOX00/IEWL/IEBCOPY:
  cc370 (committed .s, regenerated if stale)  ->  .s
  as370                                        ->  OS/360 object decks (.o)
  ar370                                        ->  libcrent.a / libufs.a / libhttpd.a
  ld370  --entry @@CRT0 --include @@CRT1 ...    ->  load module (+ --unload/--xmit)
  upload + RECV370                             ->  member in HTTPD.LINKLIB2

Each project's committed .s are the cc370 output; a .s older than its .c is
regenerated with the current cc370 -O1 before assembly.  Every module is linked
with the new conflict-aware autocall + --include @@CRT1 machinery and ld370's
unresolved-ER check (a missing function fails the link, not the running server).

Phases (run individually or 'all'):
  archives   assemble every source, build the three .a
  link MOD   link one module locally (sanity checks, no MVS)
  install MOD   link + xmit + RECV370 into HTTPD.LINKLIB2
  all        archives, then link+install all 7 members
"""
import os, sys, glob, re, subprocess, concurrent.futures as cf

HOME = os.path.expanduser("~")
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # <repo>/ld/tests/ -> <repo>
CC370 = f"{HOME}/.local/bin/i370-ibm-mvspdp-gcc"
AS370 = f"{REPO}/as/as370"
AR370 = f"{REPO}/ld/ar370"
LD370 = f"{REPO}/ld/ld370"

MVS = f"{HOME}/repos/mvs"
WORK = "/tmp/linklib2"
TARGET_DSN = "HTTPD.LINKLIB2"

# crent maclib search path for as370 (the cc370 .s + hand-asm reference these)
ASMINC = ["-I", f"{MVS}/crent370/maclib", "-I", f"{MVS}/crent370/sysmac", "-I", "/tmp/sys1mac"]

# --- project definitions -------------------------------------------------
# c_dirs: where the .c/.s live;  asm_dirs: hand-written .asm;  cflags/inc for cc370
def hpaths(*rel):
    return [f"{MVS}/httpd/{r}" for r in rel]

PROJECTS = {
    "crent": dict(
        archive=f"{WORK}/libcrent.a",
        # crent project.toml c_dirs -- NOT all of src/ (excludes src/wip work-in-progress)
        c_dirs=[f"{MVS}/crent370/src/{d}" for d in
                ("clib", "cmtt", "crypto", "dyn75", "jes", "os", "racf", "smf", "thdmgr", "time64")],
        asm_dirs=[f"{MVS}/crent370/asm"],
        compile_all=True,   # 71 .c (e.g. @@renmem, @@stow, time64) have no committed .s
        cflags=["-O1", '-DVERSION="1.0.11-dev"'],
        inc=["-I" + p for p in [f"{MVS}/crent370/include",
                                f"{MVS}/crent370/src/thdmgr",
                                f"{MVS}/crent370/src/time64"]]),
    "ufs": dict(
        archive=f"{WORK}/libufs.a",
        # ONLY the libufs CLIENT library (client/libufs) -- NOT ufsd/src/ (the
        # daemon: UFSDCLNP, UFSD#*), which is a separate application.  httpd talks
        # to the daemon via the SSI at RUNTIME, never links it.  Including src/
        # dragged UFSDCLNP into HTTPD via dep_includes="*" -> the server ran
        # UFSDCLNP instead of httpd.  Exclude libufstst (the test main).
        c_dirs=[f"{MVS}/ufsd/client"],
        exclude=["libufstst"],
        asm_dirs=[],
        cflags=["-std=gnu99"], inc=["-I" + f"{MVS}/ufsd/include"]),
    "httpd": dict(
        archive=f"{WORK}/libhttpd.a",
        c_dirs=[f"{MVS}/httpd/src", f"{MVS}/httpd/credentials/src"],
        asm_dirs=[],
        cflags=["-O1"],
        inc=["-I" + p for p in hpaths("include", "credentials/include",
                                      "contrib/crent370-1.0.9/include",
                                      "contrib/ufsd-1.0.0-dev/include")]),
    "mvsmf": dict(
        archive=f"{WORK}/libmvsmf.a",
        c_dirs=[f"{MVS}/mvsmf/src"],
        asm_dirs=[],
        cflags=["-O1", '-DVERSION="1.0.0-dev"'],   # mbt injects -DVERSION (mbtconfig.py)
        compile_all=True,   # mvsmf does NOT commit .s -- compile every .c with cc370
        inc=["-I" + p for p in [f"{MVS}/mvsmf/include",
                                f"{MVS}/mvsmf/contrib/crent370-1.0.10/include",
                                f"{MVS}/mvsmf/contrib/ufsd-1.0.0-dev/include",
                                f"{MVS}/mvsmf/contrib/httpd-4.0.0-dev/include"]]),
}


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def ar_offsets(path):
    """{member-header offset -> member name} for a GNU ar archive (matches the
    '@<off>' that ld370's -v trace prints for include/autocall pulls)."""
    data = open(path, "rb").read()
    p, longnames, out = 8, b"", {}
    while p + 60 <= len(data):
        name = data[p:p + 16].decode("latin1").rstrip()
        size = int(data[p + 48:p + 58].decode("latin1").strip())
        nm = name
        if name == "//":
            longnames = data[p + 60:p + 60 + size]
        elif name.startswith("/") and name != "/":
            o = int(name[1:]); end = longnames.find(b"\n", o)
            nm = longnames[o:end].decode("latin1")
        if name != "/" and name != "//":
            out[p] = nm.rstrip("/")
        p += 60 + size + (size & 1)
    return out


def regen_if_stale(cfile, sfile, proj):
    """regenerate an EXISTING sfile from cfile with current cc370 when the .c is
    newer.  A .c with no committed .s is NOT part of the build set (crent has 71
    such .c, never compiled) -- leave it out, do not synthesise a .s.  EXCEPT a
    compile_all project (mvsmf) commits no .s: compile every .c."""
    if not proj.get("compile_all"):
        if not os.path.exists(sfile):
            return None
        if os.path.getmtime(cfile) <= os.path.getmtime(sfile):
            return None
    elif os.path.exists(sfile) and os.path.getmtime(cfile) <= os.path.getmtime(sfile):
        return None
    cmd = [CC370] + proj["cflags"] + proj["inc"] + ["-S", cfile, "-o", sfile]
    r = run(cmd)
    if not os.path.exists(sfile) or os.path.getsize(sfile) == 0:
        return f"cc370 FAILED {os.path.basename(cfile)}:\n" + \
               "\n".join(l for l in r.stderr.splitlines() if "re-asserted" not in l)[:600]
    return f"regenerated {os.path.basename(sfile)}"


def assemble(sfile, ofile):
    r = run([AS370] + ASMINC + ["-o", ofile, sfile])
    if not os.path.exists(ofile) or os.path.getsize(ofile) == 0:
        msg = "\n".join(l for l in (r.stderr or r.stdout).splitlines())[:400]
        return f"AS370 FAIL {os.path.basename(sfile)}: {msg}"
    return None


def build_archive(name):
    proj = PROJECTS[name]
    odir = f"{WORK}/obj/{name}"
    os.makedirs(odir, exist_ok=True)
    # gather .s (regenerating stale) and .asm
    src_s, src_asm = [], []
    excl = proj.get("exclude", [])
    for d in proj["c_dirs"]:
        for c in sorted(glob.glob(f"{d}/**/*.c", recursive=True)):
            if any(x in os.path.basename(c) for x in excl):
                continue
            s = c[:-2] + ".s"
            note = regen_if_stale(c, s, proj)
            if note and note.startswith(("cc370 FAILED",)):
                print("  " + note); return None
            if note:
                print("  " + note)
            if os.path.exists(s):
                src_s.append(s)
    for d in proj["asm_dirs"]:
        src_asm.extend(sorted(glob.glob(f"{d}/*.asm")))
    allsrc = src_s + src_asm
    print(f"[{name}] {len(src_s)} .s + {len(src_asm)} .asm -> assembling...")

    objs, fails = [], []

    def do(src):
        o = f"{odir}/{os.path.basename(src).rsplit('.', 1)[0]}.o"
        err = assemble(src, o)
        return (o, err)

    with cf.ThreadPoolExecutor(max_workers=8) as ex:
        for o, err in ex.map(do, allsrc):
            if err:
                fails.append(err)
            else:
                objs.append(o)
    if fails:
        print(f"[{name}] {len(fails)} assembly failure(s):")
        for f in fails[:15]:
            print("  " + f)
        return None
    # archive
    r = run([AR370, "rc", proj["archive"]] + sorted(objs))
    if r.returncode != 0:
        print(f"[{name}] ar370 failed: {r.stderr}"); return None
    nsym = run([AR370, "t", proj["archive"]]).stdout
    nmem = sum(1 for l in nsym.splitlines() if l.strip().endswith("bytes"))
    print(f"[{name}] OK -> {proj['archive']} ({nmem} members, {os.path.getsize(proj['archive'])} bytes)")
    return proj["archive"]


# --- module link specs (from httpd/mvsmf project.toml) ------------------
# includes  = the project.toml `include` list (force-linked by name)
# archives  = autocall libraries (-l), in resolution-priority order
# force_ufs = dep_includes ufsd="*" -> link ALL of libufs (dispatch-table
#             members reached only via function pointer, invisible to autocall)
MODULES = {
    "HTTPJES2": dict(includes=["@@CRT1", "CGISTART", "HTTPJES2"], archives=["httpd", "crent", "ufs"], force_ufs=False),
    "HTTPDM":   dict(includes=["@@CRT1", "CGISTART", "HTTPDM"],   archives=["httpd", "crent", "ufs"], force_ufs=False),
    "HTTPDMTT": dict(includes=["@@CRT1", "CGISTART", "HTTPDMTT"], archives=["httpd", "crent", "ufs"], force_ufs=False),
    "HTTPDSL":  dict(includes=["@@CRT1", "CGISTART", "HTTPDSL"],  archives=["httpd", "crent", "ufs"], force_ufs=False),
    "HTTPDSRV": dict(includes=["@@CRT1", "CGISTART", "HTTPDSRV"], archives=["httpd", "crent", "ufs"], force_ufs=False),
    "HTTPD":    dict(includes=["@@CRT1", "HTTPSTRT", "HTTPD", "HTTPPRM"], archives=["httpd", "crent", "ufs"], force_ufs=True, ac=1),
    "MVSMF":    dict(includes=["@@CRT1", "CGXSTART", "MVSMF", "ROUTER", "AUTHMW", "LOGMW",
                               "COMMON", "JSON", "DSAPI", "JOBSAPI", "INFOAPI", "USSAPI", "TESTAPI"],
                     archives=["mvsmf", "httpd", "crent", "ufs"], force_ufs=True),
}


def link_module(mod):
    """link one module locally; return (lm_path, trace) on success else (None, trace)"""
    spec = MODULES[mod]
    os.makedirs(f"{WORK}/lm", exist_ok=True)
    lm = f"{WORK}/lm/{mod}.lm"
    unl = f"{WORK}/lm/{mod}.unl"
    xmit = f"{WORK}/lm/{mod}.xmit"
    cmd = [LD370, "-v", "-o", lm, "--name", mod, "--entry", "@@CRT0"]
    if spec.get("ac"):                                   # SETCODE AC(n) -> PDS2 APF section
        cmd += ["--ac", str(spec["ac"])]
    incs = list(spec["includes"])
    # force ALL of libufs (dep_includes ufsd="*") via --include, NOT as explicit
    # objects: explicit objects are placed BEFORE the includes, which would shove
    # @@crt1.o (and thus the @@CRT0 entry) past all of ufs to a high offset -- the
    # t1 0x1F88 fetch-time-S0C4 signature.  As includes (after @@CRT1) @@crt1.o
    # stays object 0 and @@CRT0 lands at offset 0, the IEWL-ENTRY-equivalent.
    if spec["force_ufs"]:
        for off, name in sorted(ar_offsets(f"{WORK}/libufs.a").items()):
            base = name[:-2] if name.endswith(".o") else name
            incs.append(base)
    for inc in incs:
        cmd += ["--include", inc]
    for a in spec["archives"]:
        cmd += ["-L", WORK, "-l", a]
    cmd += ["--unload", unl, "--xmit", xmit, "--dsn", TARGET_DSN]
    r = run(cmd)
    trace = r.stdout + r.stderr
    if r.returncode != 0 or not os.path.exists(lm):
        print(f"[{mod}] LINK FAILED (rc={r.returncode})")
        for l in trace.splitlines():
            if any(k in l for k in ("unresolved", "ld370:", "ERROR", "too many", "overflow")):
                print("    " + l)
        return None, trace
    # --- advisor sanity checks ---
    # map every pulled member (include + autocall) to its archive member name,
    # so we can prove EXACTLY ONE @@CRT0 definer was linked: @@crt1.o (the chosen
    # no-IDENTIFY startup) must be in; @@crt0.o and @@crtm.o (the other two @@CRT0
    # definers) must be OUT -- pulling either would duplicate @@CRT0 (the S0C4).
    aoff = [ar_offsets(f"{WORK}/lib{a}.a") for a in spec["archives"]]
    pulled = set()
    import re as _re
    for l in trace.splitlines():
        m = _re.search(r"(?:include|autocall): '[^']*' -> archive (\d+) member @(\d+)", l)
        if m:
            ai, off = int(m.group(1)), int(m.group(2))
            pulled.add(aoff[ai].get(off, f"?@{off}"))
    done = next((l for l in trace.splitlines() if "wrote" in l and "load module" in l), "")
    nblk = next((l for l in trace.splitlines() if "unload: member" in l), "")
    inccrt1 = [l for l in trace.splitlines() if "include: '@@CRT1'" in l]
    ok = True
    print(f"[{mod}] linked: {done.strip() or lm}")
    print(f"          {nblk.strip()}  ({len(pulled)} members)")

    def check(cond, msg):
        nonlocal ok
        print(f"    [{'ok' if cond else 'XX'}] {msg}")
        if not cond:
            ok = False
    # entry offset: @@crt1.o is included first (object 0), so @@CRT0 must resolve
    # LOW (~0).  A high offset is the t1 S0C4 signature (@@CRT0 shoved to 0x1F88
    # by a second startup definer) -> fetch-time fault.  This is the one check
    # that targets WHERE the entry landed, the historical failure variable.
    em = re.search(r"--entry @@CRT0 -> ([0-9A-Fa-f]+)", trace)
    entoff = int(em.group(1), 16) if em else -1
    check(bool(inccrt1), "--include @@CRT1 fired (no-IDENTIFY startup chosen)")
    check("@@crt1.o" in pulled, "@@crt1.o linked")
    check("@@crt0.o" not in pulled, "@@crt0.o NOT pulled (would duplicate @@CRT0)")
    check("@@crtm.o" not in pulled, "@@crtm.o bundle NOT pulled (conflict-aware autocall held)")
    check("@@exita.o" in pulled, "@@EXITA resolved to standalone @@exita.o")
    check(0 <= entoff < 0x100, f"@@CRT0 entry at low offset 0x{entoff:X} (not shoved high -> no fetch-time S0C4)")
    return (lm if ok else None), trace


def cmd_link(mods):
    names = mods or [m for m in MODULES]
    bad = []
    for m in names:
        if m not in MODULES:
            print(f"unknown module {m}"); bad.append(m); continue
        lm, _ = link_module(m)
        if lm is None:
            bad.append(m)
    print("=== link:", "ALL OK ===" if not bad else f"FAILED: {bad} ===")
    return 0 if not bad else 1


def mvs_client():
    """connect to MVS via the mbt config that lives in the crent370 project."""
    sys.path.insert(0, f"{MVS}/mbt/scripts")
    os.chdir(f"{MVS}/crent370")
    from mbt.config import MbtConfig       # noqa: E402
    from mbt.jcl import jobcard            # noqa: E402
    from mbt.mvsmf import MvsMFClient      # noqa: E402
    cfg = MbtConfig()
    cl = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port, user=cfg.mvs_user, password=cfg.mvs_pass)
    return cfg, cl, jobcard


def cmd_install(mods):
    """link + xmit each module, upload, and RECV370-install into HTTPD.LINKLIB2
    in one multi-step job (first step creates the library, the rest extend it)."""
    names = mods or list(MODULES)
    # 1. link every module locally (sanity-checked) -> per-module XMIT
    xmits = {}
    for m in names:
        lm, _ = link_module(m)
        if lm is None:
            print(f"=== install ABORTED: {m} failed to link ==="); return 1
        xmits[m] = f"{WORK}/lm/{m}.xmit"

    cfg, cl, jobcard = mvs_client()
    # 2. clean slate + upload each XMIT to its own FB80 PS dataset
    for dsn in [TARGET_DSN] + [f"HTTPD.{m}.XMIT" for m in names]:
        try:
            cl.delete_dataset(dsn); print(f"  deleted {dsn}")
        except Exception:
            pass
    for m in names:
        dsn = f"HTTPD.{m}.XMIT"
        cl.create_dataset(dsn, dsorg="PS", recfm="FB", lrecl=80, blksize=3120, space=["TRK", 120, 60])
        cl.upload_binary(dsn, open(xmits[m], "rb").read())
        print(f"  uploaded {os.path.getsize(xmits[m])} bytes -> {dsn}")

    # 3. multi-step RECV370: step 1 creates LINKLIB2 (NEW,CATLG), rest DISP=SHR
    jc = jobcard("MKLL2", cfg.jes_jobclass, cfg.jes_msgclass, "HTTPD LINKLIB2")
    steps = ""
    for i, m in enumerate(names):
        if i == 0:                                       # step 1 creates LINKLIB2
            sysut2 = (f"//SYSUT2   DD DSN={TARGET_DSN},DISP=(NEW,CATLG),UNIT=SYSDA,\n"
                      f"//            SPACE=(CYL,(150,50,40)),DCB=(RECFM=U,BLKSIZE=19069)")
            cond = ""
        else:                                            # later steps extend it
            sysut2 = f"//SYSUT2   DD DSN={TARGET_DSN},DISP=SHR"
            cond = ",COND=EVEN"
        steps += f"""//R{i:02d}      EXEC PGM=RECV370,REGION=6144K{cond}
//STEPLIB  DD DSN=SYSC.LINKLIB,DISP=SHR
//RECVLOG  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(30,15)),DISP=(NEW,DELETE)
{sysut2}
//XMITIN   DD DSN=HTTPD.{m}.XMIT,DISP=SHR
"""
    jcl = jc + "\n" + steps + "//\n"
    print(f"\n  submitting {len(names)}-step RECV370 job -> {TARGET_DSN} ...")
    res = cl.submit_jcl(jcl, wait=True, timeout=600)
    open(f"{WORK}/install.txt", "w").write(res.spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} ===")
    import re
    installed = []
    for ln in res.spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEB147I|UABEND|SUCCESSFULLY  LOADED|U0200", ln):
            print("  " + ln.rstrip())
        m = re.search(r"IEB154I\s+(\S+)\s+HAS BEEN", ln)
        if m:
            installed.append(m.group(1))
    print(f"\n=== installed members: {sorted(set(installed))} ===")
    missing = [m for m in names if m not in installed]
    if missing:
        print(f"=== MISSING: {missing} -- inspect {WORK}/install.txt ==="); return 1
    print(f"=== all {len(names)} member(s) in {TARGET_DSN} ===")
    return 0


def cmd_archives(which):
    os.makedirs(WORK, exist_ok=True)
    names = which or ["crent", "ufs", "httpd", "mvsmf"]
    ok = True
    for n in names:
        if build_archive(n) is None:
            ok = False
            print(f"=== {n} archive FAILED ===")
    print("=== archives:", "ALL OK ===" if ok else "FAILURES ===")
    return 0 if ok else 1


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        print(__doc__); sys.exit(2)
    phase = args[0]
    if phase == "archives":
        sys.exit(cmd_archives(args[1:]))
    elif phase == "link":
        sys.exit(cmd_link(args[1:]))
    elif phase == "install":
        sys.exit(cmd_install(args[1:]))
    else:
        print(f"phase '{phase}' not yet implemented in this revision")
        sys.exit(2)
