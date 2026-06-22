#!/usr/bin/env python3
"""Validate the --pack PDS2 directory fix (modlen + entry) on real MVS.

Builds two members as single-member -iebcopy (the self-describing form that
carries the real entry+modlen), packs them from those .iebcopy files, installs
via RECV370, then AMBLISTs + runs both:

  BIGENT  ~1 KB module, ENTRY at the END (offset ~1000) -- if --pack loses the
          entry (the old bug -> PDS2EPA 0), it loads at offset 0, executes the
          zero filler and abends.  Running RC=7 proves the entry was recovered.
  SMALL   entry 0, RC=3 -- the ordinary case.

AMBLIST LISTLOAD shows LENGTH OF LOAD MODULE / entry so the SIZE column that read
8 before the fix can be eyeballed too.

Usage:  python3 ld370/tests/run_pack_entry_mvs.py
"""
import os
import re
import sys
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
LD370 = os.path.join(REPO, "ld370", "ld370")
WORK = "/tmp/packentry"

# BIGENT: 1000 bytes of zero filler, then the real entry GO (LA 15,7; BR 14).
BIGENT = ("BIGENT   CSECT\n"
          "         DC    250F'0'\n"
          "GO       LA    15,7\n"
          "         BR    14\n"
          "         END   GO\n")
SMALL = ("SMALL    CSECT\n"
         "         LA    15,3\n"
         "         BR    14\n"
         "         END   SMALL\n")
MEMBERS = [("BIGENT", BIGENT, 7), ("SMALL", SMALL, 3)]


def sh(cmd, **kw):
    print("+ " + " ".join(cmd)); return subprocess.run(cmd, check=True, **kw)


def build_iebcopy(name, src):
    s = os.path.join(WORK, name + ".s"); o = os.path.join(WORK, name + ".o")
    open(s, "w").write(src)
    sh([AS370, "-o", o, s])
    sh([LD370, "-o", os.path.join(WORK, name), "--name", name, o, "-iebcopy"])
    return os.path.join(WORK, name + ".iebcopy")


def main():
    os.makedirs(WORK, exist_ok=True)
    iebs = [(n, build_iebcopy(n, src), rc) for n, src, rc in MEMBERS]

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig(); hlq = cfg.get("mvs.hlq")
    xmit_dsn = f"{hlq}.PACKENT.XMIT"; rcv_dsn = f"{hlq}.PACKENT.RCV"

    deploy = os.path.join(WORK, "deploy")
    packspec = [f"{n}={p}" for n, p, _ in iebs]
    sh([LD370, "-v", "--pack", *packspec, "-o", deploy, "-xmit", "--dsn", xmit_dsn])
    xmit = deploy + ".xmit"

    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)
    for dsn in (rcv_dsn, xmit_dsn):
        try: client.delete_dataset(dsn)
        except Exception: pass
    client.create_dataset(xmit_dsn, dsorg="PS", recfm="FB", lrecl=80,
                          blksize=3120, space=["TRK", 30, 15])
    client.upload_binary(xmit_dsn, open(xmit, "rb").read())
    print(f"  uploaded {os.path.getsize(xmit)} bytes -> {xmit_dsn}")

    jc = jobcard("PACKENT", cfg.jes_jobclass, cfg.jes_msgclass, "PACK ENTRY/SIZE")
    jcl = f"""{jc}
//RECV     EXEC PGM=RECV370,REGION=6144K
//STEPLIB  DD DSN=SYSC.LINKLIB,DISP=SHR
//RECVLOG  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(20,10)),DISP=(NEW,DELETE)
//SYSUT2   DD DSN={rcv_dsn},DISP=(NEW,CATLG),UNIT=SYSDA,
//            SPACE=(CYL,(2,1,10)),DCB=(RECFM=U,BLKSIZE=19069)
//XMITIN   DD DSN={xmit_dsn},DISP=SHR
//LIST     EXEC PGM=AMBLIST,COND=(0,NE,RECV)
//SYSLIB   DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTLOAD OUTPUT=MODLIST,MEMBER=BIGENT
 LISTLOAD OUTPUT=MODLIST,MEMBER=SMALL
//RUNBIG   EXEC PGM=BIGENT,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSUDUMP DD SYSOUT=*
//RUNSML   EXEC PGM=SMALL,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSUDUMP DD SYSOUT=*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    open(os.path.join(WORK, "packent_run.txt"), "w").write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")
    for ln in spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEB183I|UABEND|SUCCESSFULLY|COND CODE|"
                     r"LENGTH OF|ENTRY|MAIN ENTRY|MODULE|ABEND|SYSTEM=", ln):
            print("  " + ln.rstrip())

    loaded = re.findall(r"IEB154I\s+(\S+)\s+HAS BEEN\s+SUCCESSFULLY\s+LOADED", spool)
    cc = {}
    for ln in spool.splitlines():
        m = re.search(r"\b(RUNBIG|RUNSML)\b.*COND CODE\s+(\d{4})", ln)
        if m: cc[m.group(1)] = m.group(2)
    ok = (sorted(loaded) == ["BIGENT", "SMALL"]
          and cc.get("RUNBIG") == "0007" and cc.get("RUNSML") == "0003")
    print(f"\n  loaded={loaded}  RUNBIG={cc.get('RUNBIG')} (want 0007, proves entry recovered)  "
          f"RUNSML={cc.get('RUNSML')} (want 0003)")
    print("\n==> PACK ENTRY/SIZE: " + ("PASS" if ok else "FAIL -- inspect packent_run.txt"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
