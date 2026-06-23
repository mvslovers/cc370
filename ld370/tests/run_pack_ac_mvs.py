#!/usr/bin/env python3
"""Validate that --pack preserves the per-member APF authorization code (AC) on
real MVS.

Builds two members as single-member -iebcopy with DIFFERENT ACs (FTPD --ac 1,
SSIR --ac 0), packs them from those .iebcopy files, installs via RECV370, then
IEHLIST LISTPDS FORMAT prints the directory so the per-member AC can be read
back.  Before the fix, --pack templated the AC to 0 for every member; now the
whole PDS2 user-data is carried from the input directory, so FTPD keeps AC=01.

Usage:  python3 ld370/tests/run_pack_ac_mvs.py
"""
import os
import re
import sys
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
LD370 = os.path.join(REPO, "ld370", "ld370")
WORK = "/tmp/packac"

# (member, AC) -- distinct ACs so a pass proves each member keeps its OWN code.
MEMBERS = [("FTPD", 1), ("SSIR", 0)]


def sh(cmd, **kw):
    print("+ " + " ".join(cmd)); return subprocess.run(cmd, check=True, **kw)


def build_iebcopy(name, ac):
    s = os.path.join(WORK, name + ".s"); o = os.path.join(WORK, name + ".o")
    open(s, "w").write("%-8s CSECT\n         LA    15,0\n         BR    14\n         END   %s\n"
                       % (name, name))
    sh([AS370, "-o", o, s])
    sh([LD370, "--ac", str(ac), "-o", os.path.join(WORK, name), "--name", name, o, "-iebcopy"])
    return os.path.join(WORK, name + ".iebcopy")


def main():
    os.makedirs(WORK, exist_ok=True)
    iebs = [(n, build_iebcopy(n, ac), ac) for n, ac in MEMBERS]

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig(); hlq = cfg.get("mvs.hlq")
    xmit_dsn = f"{hlq}.PACKAC.XMIT"; rcv_dsn = f"{hlq}.PACKAC.RCV"
    vol = "WORK00"          # pin the load lib so IEHLIST LISTPDS can find it (3350 on mvsdev)

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

    jc = jobcard("PACKAC", cfg.jes_jobclass, cfg.jes_msgclass, "PACK AC PRESERVE")
    jcl = f"""{jc}
//RECV     EXEC PGM=RECV370,REGION=6144K
//STEPLIB  DD DSN=SYSC.LINKLIB,DISP=SHR
//RECVLOG  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(20,10)),DISP=(NEW,DELETE)
//SYSUT2   DD DSN={rcv_dsn},DISP=(NEW,CATLG),
//            UNIT=SYSDA,VOL=SER={vol},
//            SPACE=(CYL,(2,1,10)),DCB=(RECFM=U,BLKSIZE=19069)
//XMITIN   DD DSN={xmit_dsn},DISP=SHR
//LIST     EXEC PGM=IEHLIST,COND=(0,NE,RECV)
//SYSPRINT DD SYSOUT=*
//DD1      DD UNIT=SYSDA,VOL=SER={vol},DISP=SHR
//SYSIN    DD *
 LISTPDS DSNAME={rcv_dsn},VOL=3350={vol},FORMAT
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    open(os.path.join(WORK, "packac_run.txt"), "w").write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")
    auth = {}
    for ln in spool.splitlines():
        if re.search(r"IEB154I|SUCCESSFULLY|COND CODE|MEMBER|FTPD|SSIR|ATTR", ln, re.I):
            print("  " + ln.rstrip())
        m = re.match(r"\s+(FTPD|SSIR)\s+\S+\s+\S+.*\s(YES|NO)\s*$", ln)
        if m:
            auth[m.group(1)] = m.group(2)
    ok = auth.get("FTPD") == "YES" and auth.get("SSIR") == "NO"
    print(f"\n  AUTH column: FTPD={auth.get('FTPD')} (want YES=AC1)  SSIR={auth.get('SSIR')} (want NO=AC0)")
    print("\n==> PACK AC PRESERVE: " + ("PASS" if ok else "FAIL -- inspect packac_run.txt"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
