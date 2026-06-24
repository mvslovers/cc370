#!/usr/bin/env python3
"""Validate the multi-block PDS directory on real MVS.

Packs 8 members (M1..M8 -> RC 1..8) into one library.  8 > 6, so the directory
spills into TWO 256-byte blocks (block 0 = 7 entries, block 1 = M8 + the FF
terminator).  Before the fix this SIGABRTed at the 7th member; the bug is the
directory, so the test crosses the block boundary.  Installs via RECV370, checks
all 8 STOW (IEB154I x8), and runs M1 (block 0) and M8 (block 1) to prove a member
in the SECOND directory block is found and loadable.

Usage:  python3 ld370/tests/run_multiblock_mvs.py
"""
import os
import re
import sys
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
LD370 = os.path.join(REPO, "ld370", "ld370")
WORK = "/tmp/mblock"
MEMBERS = [("M%d" % i, i) for i in range(1, 9)]   # M1..M8 -> RC 1..8


def sh(cmd, **kw):
    print("+ " + " ".join(cmd)); return subprocess.run(cmd, check=True, **kw)


def build_iebcopy(name, rc):
    s = os.path.join(WORK, name + ".s"); o = os.path.join(WORK, name + ".o")
    open(s, "w").write("%-8s CSECT\n         LA    15,%d\n         BR    14\n         END   %s\n"
                       % (name, rc, name))
    sh([AS370, "-o", o, s])
    sh([LD370, "-o", os.path.join(WORK, name), "--name", name, o, "-iebcopy"])
    return os.path.join(WORK, name + ".iebcopy")


def main():
    os.makedirs(WORK, exist_ok=True)
    iebs = [(n, build_iebcopy(n, rc), rc) for n, rc in MEMBERS]

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig(); hlq = cfg.get("mvs.hlq")
    xmit_dsn = f"{hlq}.MBLOCK.XMIT"; rcv_dsn = f"{hlq}.MBLOCK.RCV"

    deploy = os.path.join(WORK, "deploy")
    sh([LD370, "-v", "--pack", *[p for _, p, _ in iebs], "-o", deploy, "-xmit", "--dsn", xmit_dsn])
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

    jc = jobcard("MBLOCK", cfg.jes_jobclass, cfg.jes_msgclass, "MULTI-BLOCK DIR")
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
//RUNM1    EXEC PGM=M1,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSUDUMP DD SYSOUT=*
//RUNM8    EXEC PGM=M8,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSUDUMP DD SYSOUT=*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    open(os.path.join(WORK, "mblock_run.txt"), "w").write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")
    loaded = re.findall(r"IEB154I\s+(\S+)\s+HAS BEEN\s+SUCCESSFULLY\s+LOADED", spool)
    bad = [m for m in ("IEB139I", "IEB183I", "UABEND") if m in spool]
    cc = {}
    for ln in spool.splitlines():
        m = re.search(r"\b(RUNM1|RUNM8)\b.*COND CODE\s+(\d{4})", ln)
        if m: cc[m.group(1)] = m.group(2)
    for ln in spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEB183I|UABEND|COND CODE", ln):
            print("  " + ln.rstrip())
    ok = (sorted(loaded) == sorted(n for n, _ in MEMBERS) and not bad
          and cc.get("RUNM1") == "0001" and cc.get("RUNM8") == "0008")
    print(f"\n  loaded {len(loaded)}/8 members; RUNM1={cc.get('RUNM1')} (want 0001, block 0) "
          f"RUNM8={cc.get('RUNM8')} (want 0008, block 1)")
    print("\n==> MULTI-BLOCK DIRECTORY: " + ("PASS" if ok else "FAIL -- inspect mblock_run.txt"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
