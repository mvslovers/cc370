#!/usr/bin/env python3
"""End-to-end multi-member: pack TWO distinct load-module members into ONE
host-built XMIT (ld370 --pack -xmit), ship it to MVS, RECV370-install it, and
run BOTH members.  This is the arbiter for the per-member-DL=0-EOF unload fix --
the host-side unload_check.py simulates IEBRSAM, but only the real reload proves
it.

The two members return DIFFERENT codes (E2EA -> 7, E2EB -> 3) so a pass proves
not just that both reload (IEB154I x2) but that they stay DISTINCT -- correct
per-member directory TTRs, no cross-contamination.  The whole chain is
host-native: as370 assembles, ld370 links + packs + emits the XMIT; only the
final library touches MVS, via one RECV370 step.

  RECV step -> transport + multi-member layout (IEB154I E2EA + IEB154I E2EB,
               no IEB183I/IEB139I).
  RUN steps -> E2EA cond code 0007, E2EB cond code 0003.

Usage:
  python3 ld370/tests/run_2mem_mvs.py             # full round-trip
  python3 ld370/tests/run_2mem_mvs.py --link-only # build + pack + XMIT, no MVS
"""
import os
import re
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
LD370 = os.path.join(REPO, "ld370", "ld370")
WORK = "/tmp/e2e2"

# (member, return code) -- distinct RCs so a pass proves the members stay distinct
MEMBERS = [("E2EA", 7), ("E2EB", 3)]


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def build_member(name, rc):
    """Assemble + link a minimal runnable member that returns `rc` (LA 15,rc; BR 14)."""
    src = os.path.join(WORK, name + ".s")
    obj = os.path.join(WORK, name + ".o")
    lm = os.path.join(WORK, name + ".lm")
    with open(src, "w") as fp:
        fp.write("%-8s CSECT\n         LA    15,%d\n         BR    14\n         END   %s\n"
                 % (name, rc, name))
    sh([AS370, "-o", obj, src])
    sh([LD370, "-o", lm, "--name", name, obj])
    return lm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--link-only", action="store_true",
                    help="build + pack + emit XMIT only, skip the MVS round-trip")
    args = ap.parse_args()

    os.makedirs(WORK, exist_ok=True)
    for tool in (AS370, LD370):
        if not os.path.exists(tool):
            sys.exit(f"missing {tool} -- run `make tools` first")

    # --- host: build both members, pack into one XMIT ----------------------
    lms = [build_member(n, rc) for n, rc in MEMBERS]

    # MVS connectivity + HLQ come from the mbt config (lives in crent370).
    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    xmit_dsn = f"{hlq}.E2E2.XMIT"
    rcv_dsn = f"{hlq}.E2E2.RCV"

    deploy = os.path.join(WORK, "deploy")
    packspec = [f"{n}={WORK}/{n}.lm" for n, _ in MEMBERS]
    sh([LD370, "-v", "--pack", *packspec, "-o", deploy, "-xmit", "--dsn", xmit_dsn])
    xmit = deploy + ".xmit"

    # host-side faithful reload check before spending the round-trip
    sh([sys.executable, os.path.join(REPO, "ld370", "tests", "unload_check.py"),
        deploy + ".iebcopy", *packspec])

    if args.link_only:
        print(f"\n[link-only] wrote {xmit} -> target {xmit_dsn}")
        return

    # --- MVS: upload, RECV370-install, run both -----------------------------
    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)
    for dsn in (rcv_dsn, xmit_dsn):
        try:
            client.delete_dataset(dsn)
            print(f"  deleted pre-existing {dsn}")
        except Exception:
            pass

    client.create_dataset(xmit_dsn, dsorg="PS", recfm="FB", lrecl=80,
                          blksize=3120, space=["TRK", 30, 15])
    with open(xmit, "rb") as fp:
        client.upload_binary(xmit_dsn, fp.read())
    print(f"  uploaded {os.path.getsize(xmit)} bytes -> {xmit_dsn} (FB80)")

    jc = jobcard("E2E2RUN", cfg.jes_jobclass, cfg.jes_msgclass, "MULTI-MEMBER PACK")
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
//RUNA     EXEC PGM=E2EA,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//RUNB     EXEC PGM=E2EB,COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    with open(os.path.join(WORK, "e2e2_run.txt"), "w") as fp:
        fp.write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")

    # --- RECV milestone: both members STOWed, no I/O abend ------------------
    loaded = re.findall(r"IEB154I\s+(\S+)\s+HAS BEEN\s+SUCCESSFULLY\s+LOADED", spool)
    bad = [m for m in ("IEB139I", "IEB183I", "UABEND") if m in spool]
    print("\n--- RECV (transport + multi-member layout) ---")
    for ln in spool.splitlines():
        if re.search(r"IEB15[14]I|IEB139I|IEB183I|UABEND|RECVCTL|SUCCESSFULLY LOADED", ln):
            print("  " + ln.rstrip())
    print(f"  => loaded members: {loaded}  {'(bad: ' + ','.join(bad) + ')' if bad else ''}")

    # --- RUN milestone: each member's own cond code -------------------------
    print("\n--- RUN (per-member correctness) ---")
    cc = {}
    for ln in spool.splitlines():
        m = re.search(r"-(RUN[AB])\b.*COND CODE\s+(\d{4})", ln) or \
            re.search(r"\b(RUN[AB])\b.*COND CODE\s+(\d{4})", ln)
        if m:
            cc[m.group(1)] = m.group(2)
        if re.search(r"IEF142I|IEF472I|COND CODE|ABEND|SYSTEM=|COMPLETION CODE", ln):
            print("  " + ln.rstrip())
    exp = {"RUNA": "0007", "RUNB": "0003"}
    ok = (sorted(loaded) == ["E2EA", "E2EB"] and not bad and cc == exp)
    print(f"  => RUNA={cc.get('RUNA')} (want 0007)  RUNB={cc.get('RUNB')} (want 0003)")
    print("\n==> MULTI-MEMBER ROUND-TRIP: " + ("PASS" if ok else "FAIL -- inspect e2e2_run.txt"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
