#!/usr/bin/env python3
"""End-to-end: link a real C program against the crent370 runtime entirely on
the host (cc370 -> as370 -> ld370 --xmit), ship it to MVS as an FB80 XMIT, and
materialise + run it with RECV370.  This is the "a C program runs" milestone.

The chain is fully host-native -- no IFOX00, no IEWL, no IEBCOPY, no TRANSMIT.
Only the final load module touches MVS, via one RECV370 step.

Two milestones are read SEPARATELY (they fail in different places):

  * RECV step  -> the multi-track XMIT transport (IEB154I = clean reload).
                  t1's member is ~69KB / 11 one-block-per-track tracks (< 1
                  cylinder) -- the same geometry e2e validated, just more
                  records.  A clean reload proves the transport carries a real
                  C-program-sized member.
  * RUN step   -> link/fetch correctness (multi-chunk text, entry, weak
                  externals).  COND CODE 0007 = the program ran and returned 7.

Prerequisites (host):
  * cc370 driver installed  (i370-ibm-mvspdp-gcc / c2asm370 symlink)
  * as370, ld370 built in this repo
  * libcrent.a  -- the crent370 runtime archived by ar370 (see --lib);
                   built once via the as370+ar370 loop over crent370 sources.

Usage:
  python3 ld/tests/run_t1_mvs.py            # full round-trip
  python3 ld/tests/run_t1_mvs.py --link-only  # host link + emit XMIT, no MVS
"""
import os
import re
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LD370 = os.path.join(REPO, "ld", "ld370")
CC370 = os.path.expanduser("~/.local/bin/i370-ibm-mvspdp-gcc")

DEF_LIB = "/tmp/libcrent.a"     # crent370 runtime archive (ar370 output)
WORK = "/tmp/t1run"             # host scratch for the built artifacts
MEMBER = "T1"                   # PDS member name = program name


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lib", default=DEF_LIB, help="crent370 runtime archive")
    ap.add_argument("--work", default=WORK, help="host scratch dir")
    ap.add_argument("--link-only", action="store_true",
                    help="host link + emit XMIT only, skip the MVS round-trip")
    args = ap.parse_args()

    if not os.path.exists(args.lib):
        sys.exit(f"missing runtime archive {args.lib} -- build libcrent.a first")

    # --- host: compile + link + emit the FB80 XMIT -------------------------
    os.makedirs(args.work, exist_ok=True)
    csrc = os.path.join(args.work, "t1.c")
    with open(csrc, "w") as fp:
        fp.write("int main(void) { return 7; }\n")
    obj = os.path.join(args.work, "t1.o")
    lm = os.path.join(args.work, "t1.lm")
    unl = os.path.join(args.work, "t1.unl")
    xmit = os.path.join(args.work, "t1.xmit")

    sh([CC370, "-O1", "-c", csrc, "-o", obj])

    # MVS connectivity + HLQ come from the mbt config, which lives in the
    # crent370 project (the runtime we link against); resolve the target DSNs
    # now so --dsn stamps the right INMDSNAM into the XMIT.
    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    xmit_dsn = f"{hlq}.{MEMBER}.XMIT"
    rcv_dsn = f"{hlq}.{MEMBER}.RCV"

    sh([LD370, "-v", "-o", lm, "--name", MEMBER, "--unload", unl,
        "--xmit", xmit, "--dsn", xmit_dsn, obj, args.lib])

    if args.link_only:
        print(f"\n[link-only] wrote {xmit} -> target {xmit_dsn}")
        return

    # --- MVS: upload the XMIT, RECV370-install, run ------------------------
    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)

    # clean slate: RECV370 STOWs into a NEW,CATLG dataset, and the XMIT PS must
    # match FB80, so delete any leftovers from a prior run.
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

    jc = jobcard("T1RUN", cfg.jes_jobclass, cfg.jes_msgclass, "HOST C PROGRAM RUN")
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
//RUN      EXEC PGM={MEMBER},COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    with open(os.path.join(args.work, "t1_run.txt"), "w") as fp:
        fp.write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")

    # --- read the two milestones separately --------------------------------
    recv_ok = "IEB154I" in spool and "IEB139I" not in spool
    print("\n--- RECV (transport milestone) ---")
    for ln in spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEB147I|IEB151I|UABEND|RECVCTL|"
                     r"SUCCESSFULLY LOADED", ln):
            print("  " + ln.rstrip())
    print(f"  => transport {'OK (clean reload)' if recv_ok else 'FAILED'}")

    print("\n--- RUN (correctness milestone) ---")
    run_cc = None
    for ln in spool.splitlines():
        m = re.search(r"\bRUN\b.*COND CODE\s+(\d+)", ln) or \
            re.search(r"IEFACTRT.*\b{0}\b.*?/(?:S-)?C?(\d+)?".format(MEMBER), ln)
        if re.search(r"IEF142I|IEF472I|COND CODE|ABEND|STEP WAS NOT|"
                     r"COMPLETION CODE|SYSTEM=|PSW", ln):
            print("  " + ln.rstrip())
        m2 = re.search(r"COND CODE\s+(\d{4})", ln)
        if m2 and "RUN" in ln:
            run_cc = m2.group(1)
    if run_cc is not None:
        print(f"  => RUN cond code {run_cc} "
              f"({'PASS (returned 7)' if run_cc == '0007' else 'unexpected'})")
    elif not recv_ok:
        print("  => RUN not reached (RECV failed)")
    else:
        print("  => RUN cond code not parsed -- inspect t1_run.txt")


if __name__ == "__main__":
    main()
