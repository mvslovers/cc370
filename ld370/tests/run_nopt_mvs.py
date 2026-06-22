#!/usr/bin/env python3
"""Multi-text-record fetch isolation: assemble a 2-CSECT NOP module that splits
into >=2 load-module text records, link it host-native (as370 -> ld370 --xmit),
ship it to MVS as an FB80 XMIT, RECV370-install it, and RUN it.

The module is pure fall-through NOPs across the chunk boundary, with NO adcons
(no RLD) and NO external refs -- so a failure can only be the multi-text-record
PLACEMENT by program fetch, isolated from relocation/autocall.  Execution NOPs
through chunk 1, crosses the chunk boundary, sets RC=0 (SR 15,15) and returns.

History: a module split into >1 text record S0C1'd at the first chunk boundary
because the PDS2 directory still carried PDS21BLK (single-text-block flag) from
the echoed template -> program fetch took the single-block load path and loaded
ONLY the first text record.  build_userdata() now computes PDS2ATR1/ATR2 from
the actual module; this test guards that the multi-text member reloads + runs.

  * RECV step -> transport (IEB154I = clean reload).
  * RUN step  -> COND CODE 0000 = fetch placed BOTH text records and it ran.

Usage:
  python3 ld/tests/run_nopt_mvs.py             # full round-trip
  python3 ld/tests/run_nopt_mvs.py --link-only # host link + emit XMIT, no MVS
  python3 ld/tests/run_nopt_mvs.py --amblist   # reload + AMBLIST LISTLOAD (disk struct)

--amblist is a diagnostic: instead of RUNning the reloaded member it inspects it
with AMBLIST LISTLOAD (OUTPUT=BOTH).  AMBLIST reads the member as data via
BPAM/BSAM -- it does NOT go through program fetch -- so its on-disk text-record
lengths / addresses discriminate a RECV370-reload truncation (short on disk) from
a program-fetch truncation (full on disk, fetch stops early).
"""
import os
import re
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LD370 = os.path.join(REPO, "ld370", "ld370")
AS370 = os.path.join(REPO, "as370", "as370")

WORK = "/tmp/noptrun"
MEMBER = "NOPT"

# 2 CSECTs of NOP fill.  ld370 packs whole sections per text record up to MAXTEXT
# (18432B); two sections whose sum exceeds MAXTEXT therefore land in 2 text
# records.  Section 1 = --t1 bytes (chunk 1), section 2 = --t2 bytes ending in
# SR 15,15 / BR 14 (chunk 2).  Defaults 12288/12288 (sum 24576 > MAXTEXT -> split).
# Execution NOPs through both sections; the abend PSW marks the first unloaded
# byte, so varying t1/t2 maps exactly where program fetch stops.
def build_asm(t1, t2):
    assert t1 % 2 == 0 and t2 % 2 == 0 and t2 >= 4, "even byte sizes, t2>=4"
    return (
        "NOPTEST  CSECT\n"
        f"NOPENT   DC    {t1 // 2}XL2'1811'      {t1}B of LR R1,R1 (NOP) -- chunk 1\n"
        "NOPSEC2  CSECT\n"
        f"         DC    {(t2 - 4) // 2}XL2'1811'      {t2 - 4}B of NOP -- chunk 2\n"
        "         SR    15,15              set return code 0\n"
        "         BR    14                 return to caller\n"
        "         END   NOPENT\n"
    )


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--work", default=WORK, help="host scratch dir")
    ap.add_argument("--link-only", action="store_true",
                    help="host link + emit XMIT only, skip the MVS round-trip")
    ap.add_argument("--amblist", action="store_true",
                    help="reload + AMBLIST LISTLOAD the member (on-disk struct) "
                         "instead of running it")
    ap.add_argument("--t1", type=int, default=12288,
                    help="chunk-1 (section NOPTEST) byte size (default 12288)")
    ap.add_argument("--t2", type=int, default=12288,
                    help="chunk-2 (section NOPSEC2) byte size, incl SR/BR (default 12288)")
    args = ap.parse_args()

    print(f"[module] t1={args.t1}B t2={args.t2}B total~={args.t1 + args.t2}B "
          f"(MAXTEXT=18432 -> {'2 text records' if args.t1 + args.t2 > 18432 else '1 text record'})")

    os.makedirs(args.work, exist_ok=True)
    asm = os.path.join(args.work, "nopt.s")
    with open(asm, "w") as fp:
        fp.write(build_asm(args.t1, args.t2))
    obj = os.path.join(args.work, "nopt.o")
    lm = os.path.join(args.work, "nopt.lm")
    unl = os.path.join(args.work, "nopt.unl")
    xmit = os.path.join(args.work, "nopt.xmit")

    sh([AS370, "-o", obj, asm])

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
        "--xmit", xmit, "--dsn", xmit_dsn, obj])

    if args.link_only:
        print(f"\n[link-only] wrote {xmit} -> target {xmit_dsn}")
        return

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

    recv_step = f"""//RECV     EXEC PGM=RECV370,REGION=6144K
//STEPLIB  DD DSN=SYSC.LINKLIB,DISP=SHR
//RECVLOG  DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSIN    DD DUMMY
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(20,10)),DISP=(NEW,DELETE)
//SYSUT2   DD DSN={rcv_dsn},DISP=(NEW,CATLG),UNIT=SYSDA,
//            SPACE=(CYL,(2,1,10)),DCB=(RECFM=U,BLKSIZE=19069)
//XMITIN   DD DSN={xmit_dsn},DISP=SHR"""

    if args.amblist:
        # AMBLIST reads the member as data (BPAM/BSAM), bypassing program fetch.
        # OUTPUT=BOTH = MODLIST (text/control records) + XREF (RLD/entry).  The
        # control statement must start in col 2.
        jobname, step2 = "NOPTLST", f"""//LIST     EXEC PGM=AMBLIST,COND=(0,NE,RECV)
//SYSLIB   DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTLOAD OUTPUT=BOTH,MEMBER={MEMBER}
/*"""
    else:
        jobname, step2 = "NOPTRUN", f"""//RUN      EXEC PGM={MEMBER},COND=(0,NE,RECV)
//STEPLIB  DD DSN={rcv_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*"""

    jc = jobcard(jobname, cfg.jes_jobclass, cfg.jes_msgclass, "MULTI-TEXT FETCH")
    jcl = f"""{jc}
{recv_step}
{step2}
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    with open(os.path.join(args.work, "nopt_run.txt"), "w") as fp:
        fp.write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")

    recv_ok = "IEB154I" in spool and "IEB139I" not in spool
    print("\n--- RECV (transport milestone) ---")
    for ln in spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEB147I|IEB151I|UABEND|RECVCTL|"
                     r"SUCCESSFULLY LOADED", ln):
            print("  " + ln.rstrip())
    print(f"  => transport {'OK (clean reload)' if recv_ok else 'FAILED'}")

    if args.amblist:
        # Dump the whole AMBLIST listing -- the discriminator is the highest text
        # address / total text length and each control record's count field.
        print("\n--- AMBLIST LISTLOAD (on-disk record structure) ---")
        out = os.path.join(args.work, "nopt_amblist.txt")
        with open(out, "w") as fp:
            fp.write(spool)
        started = False
        for ln in spool.splitlines():
            if re.search(r"AMBLIST|LISTLOAD|CONTROL RECORD|TEXT RECORD|"
                         r"RELOCATION|CONTROL SECTION|ENTRY|MODULE|RECORD|"
                         r"ADDRESS|LENGTH|ESD|IDR|TTR", ln):
                started = True
            if started and ln.strip():
                print("  " + ln.rstrip())
        print(f"\n  => full listing saved to {out}")
        return

    print("\n--- RUN (multi-text placement milestone) ---")
    run_cc = None
    for ln in spool.splitlines():
        if re.search(r"IEF142I|IEF472I|COND CODE|ABEND|STEP WAS NOT|"
                     r"COMPLETION CODE|SYSTEM=|PSW", ln):
            print("  " + ln.rstrip())
        m2 = re.search(r"COND CODE\s+(\d{4})", ln)
        if m2 and "RUN" in ln:
            run_cc = m2.group(1)
    if run_cc is not None:
        print(f"  => RUN cond code {run_cc} "
              f"({'PASS (both text records placed)' if run_cc == '0000' else 'unexpected'})")
    elif not recv_ok:
        print("  => RUN not reached (RECV failed)")
    else:
        print("  => RUN cond code not parsed -- inspect nopt_run.txt")


if __name__ == "__main__":
    main()
