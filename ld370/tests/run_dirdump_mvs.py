#!/usr/bin/env python3
"""Directory-entry DUMP oracle for the multi-text fetch-truncation bug.

The IEWL oracle proved the *member* is byte-correct and runs RC=0; the only
difference vs ld370's installed module is the PDS2 directory / physical TTRs.
This harness gets the one decisive datum host-side parsing cannot: the raw bytes
of IEWL's directory entry vs ld370's RECV370-reloaded entry -- specifically the
C-byte's #TTR count (1 = ld370's single PDS2TTRT, 2 = an extra PDS2TTRN note-list
pointer that program FETCH uses to find the 2nd+ text records).

One job, three steps:
  RECV  -- RECV370-install ld370's nopt.xmit into rcv_dsn (the failing module)
  IEWL  -- link the EXACT same nopt.o with real IEWL into iewl_dsn (the oracle)
  LIST  -- IEHLIST LISTPDS FORMAT + DUMP of BOTH directories

Then parse both directory hex dumps host-side, extract the NOPT entry (name in
EBCDIC = D5D6D7E3), and diff C-byte + 24-byte userdata byte-for-byte.

Usage:
  python3 ld/tests/run_dirdump_mvs.py [--t1 17000 --t2 2056]
"""
import os
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LD370 = os.path.join(REPO, "ld370", "ld370")
AS370 = os.path.join(REPO, "as370", "as370")
WORK = "/tmp/dirdump"
MEMBER = "NOPT"

sys.path.insert(0, os.path.join(REPO, "ld370", "tests"))
from run_nopt_mvs import build_asm                       # noqa: E402


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def parse_dir_entry(dump_hex, member="NOPT"):
    """Find the member's directory entry in a hex stream and decode it.
    dump_hex is a contiguous hex string of the directory block bytes."""
    import codecs
    name_ebc = member.ljust(8).encode("cp037").hex()
    raw = dump_hex.lower().replace(" ", "")
    idx = raw.find(name_ebc)
    if idx < 0:
        return None
    b = bytes.fromhex(raw[idx:idx + (8 + 3 + 1 + 24) * 2])
    ttr = b[8:11]
    c = b[11]
    alias, nttr, nhalf = (c & 0x80) >> 7, (c & 0x60) >> 5, c & 0x1f
    ud = b[12:12 + nhalf * 2]
    return dict(name=member, ttr=ttr.hex(), cbyte=c, alias=alias, nttr=nttr,
                nhalf=nhalf, ud=ud.hex())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--t1", type=int, default=17000)
    ap.add_argument("--t2", type=int, default=2056)
    ap.add_argument("--work", default=WORK)
    args = ap.parse_args()

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
    from mbt.config import MbtConfig                       # noqa: E402
    from mbt.jcl import jobcard                            # noqa: E402
    from mbt.mvsmf import MvsMFClient                      # noqa: E402

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    obj_dsn = f"{hlq}.NOPTDD.OBJ"
    xmit_dsn = f"{hlq}.NOPTDD.XMIT"
    rcv_dsn = f"{hlq}.NOPTDD.RCV"      # ld370 reloaded
    iewl_dsn = f"{hlq}.NOPTDD.IEWL"    # IEWL oracle

    sh([LD370, "-v", "-o", lm, "--name", MEMBER, "--unload", unl,
        "--xmit", xmit, "--dsn", xmit_dsn, obj])

    objbytes = open(obj, "rb").read()
    xmitbytes = open(xmit, "rb").read()

    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)

    for dsn in (obj_dsn, xmit_dsn, rcv_dsn, iewl_dsn):
        try:
            client.delete_dataset(dsn)
            print(f"  deleted pre-existing {dsn}")
        except Exception:
            pass

    client.create_dataset(obj_dsn, dsorg="PS", recfm="FB", lrecl=80,
                          blksize=3120, space=["TRK", 30, 15])
    client.upload_binary(obj_dsn, objbytes)
    client.create_dataset(xmit_dsn, dsorg="PS", recfm="FB", lrecl=80,
                          blksize=3120, space=["TRK", 30, 15])
    client.upload_binary(xmit_dsn, xmitbytes)
    print(f"  uploaded obj {len(objbytes)}B -> {obj_dsn}, xmit {len(xmitbytes)}B -> {xmit_dsn}")

    jc = jobcard("NOPTDD", cfg.jes_jobclass, cfg.jes_msgclass, "DIR DUMP ORACLE")
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
//LKED     EXEC PGM=IEWL,PARM='LIST,MAP,XREF,NCAL,RENT,REUS',
//            COND=EVEN
//SYSLIN   DD DSN={obj_dsn},DISP=SHR
//SYSLMOD  DD DSN={iewl_dsn}(NOPT),DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(CYL,(2,1,5)),
//            DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(5,2))
//SYSPRINT DD SYSOUT=*
//LIST     EXEC PGM=IEHLIST,COND=EVEN
//SYSPRINT DD SYSOUT=*
//DD1      DD DSN={rcv_dsn},DISP=SHR
//DD2      DD DSN={iewl_dsn},DISP=SHR
//SYSIN    DD *
 LISTPDS DSNAME={rcv_dsn},FORMAT
 LISTPDS DSNAME={rcv_dsn},DUMP
 LISTPDS DSNAME={iewl_dsn},FORMAT
 LISTPDS DSNAME={iewl_dsn},DUMP
/*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=240)
    spool = res.spool
    out = os.path.join(args.work, "dirdump.txt")
    with open(out, "w") as fp:
        fp.write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")
    print(f"  full spool -> {out}")

    # echo milestones
    import re
    print("\n--- milestones ---")
    for ln in spool.splitlines():
        if re.search(r"IEB154I|IEB139I|IEW0|RETURN CODE|IEH|COND CODE|"
                     r"FORMATTED|DIRECTORY", ln):
            print("  " + ln.rstrip())

    print(f"\n  (parse {out} for the per-dataset DUMP hex; "
          f"member entry decode below if locatable)")
    # crude: scan the raw spool hex for the NOPT entry in each DUMP section
    for tag, dsn in (("ld370(RECV)", rcv_dsn), ("IEWL", iewl_dsn)):
        # gather hex digits from the spool (best-effort; manual inspection still wins)
        ent = parse_dir_entry(spool, MEMBER)
        if ent:
            print(f"  [{tag}] first NOPT match: C=0x{ent['cbyte']:02x} "
                  f"#TTR={ent['nttr']} #half={ent['nhalf']} ud={ent['ud']}")


if __name__ == "__main__":
    main()
