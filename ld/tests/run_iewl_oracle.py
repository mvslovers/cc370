#!/usr/bin/env python3
"""IEWL oracle for the multi-text-record fetch-truncation investigation.

Links the EXACT object deck ld370 links (the 17000/2056 two-CSECT NOP module)
with REAL IEWL on MVS, then AMBLISTs the resulting member.  AMBLIST is text
output (no binary download, no RECFM=VS problem), and it shows IEWL's own
control/text record structure -- how IEWL splits the text into records, each
control record's CCW (address/flags/count), the ESD, and the module attributes.

This is the apples-to-apples comparison the investigation needs: given the same
input objects, does IEWL chunk the text differently than ld370 (which emits one
17000-byte text record + one 2056-byte text record)?  In particular, does IEWL
cap a single text record below ~16K on this SYSLMOD geometry, while ld370 emits
a >16K record that program fetch truncates?

The diff target (host-side, against the saved ld370 AMBLIST / lmdiff dump):
  * RECORD count + each control record's CCW (06 addr flags count)
  * the text-record lengths IEWL chose
  * LENGTH OF LOAD MODULE and the per-CSECT map

Usage:
  python3 ld/tests/run_iewl_oracle.py              # build + IEWL link + AMBLIST
  python3 ld/tests/run_iewl_oracle.py --t1 N --t2 M

SYSLMOD is allocated RECFM=U BLKSIZE=19069 (one 3350 track) to match the geometry
ld370's unload targets (UNLOAD_TRKPERCYL=30), so IEWL's device-driven TXTSIZE
choice is comparable.
"""
import os
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as", "as370")
WORK = "/tmp/iewloracle"
MEMBER = "NOPT"

sys.path.insert(0, os.path.join(REPO, "ld", "tests"))
from run_nopt_mvs import build_asm        # reuse the exact module source  # noqa: E402


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--t1", type=int, default=17000,
                    help="chunk-1 (NOPTEST) byte size -- the >16K record (default 17000)")
    ap.add_argument("--t2", type=int, default=2056,
                    help="chunk-2 (NOPSEC2) byte size incl SR/BR (default 2056)")
    ap.add_argument("--work", default=WORK)
    args = ap.parse_args()

    os.makedirs(args.work, exist_ok=True)
    asm = os.path.join(args.work, "nopt.s")
    with open(asm, "w") as fp:
        fp.write(build_asm(args.t1, args.t2))
    obj = os.path.join(args.work, "nopt.o")
    sh([AS370, "-o", obj, asm])
    objbytes = open(obj, "rb").read()
    print(f"[obj] {len(objbytes)} bytes = {len(objbytes)//80} FB80 cards "
          f"(t1={args.t1} t2={args.t2})")

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    obj_dsn = f"{hlq}.NOPTORC.OBJ"
    load_dsn = f"{hlq}.NOPTORC.LOAD"

    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)

    for dsn in (obj_dsn, load_dsn):
        try:
            client.delete_dataset(dsn)
            print(f"  deleted pre-existing {dsn}")
        except Exception:
            pass

    client.create_dataset(obj_dsn, dsorg="PS", recfm="FB", lrecl=80,
                          blksize=3120, space=["TRK", 30, 15])
    client.upload_binary(obj_dsn, objbytes)
    print(f"  uploaded {len(objbytes)} bytes -> {obj_dsn} (FB80)")

    jc = jobcard("NOPTORC", cfg.jes_jobclass, cfg.jes_msgclass, "IEWL ORACLE")
    jcl = f"""{jc}
//LKED     EXEC PGM=IEWL,PARM='LIST,MAP,XREF,NCAL,RENT,REUS'
//SYSLIN   DD DSN={obj_dsn},DISP=SHR
//SYSLMOD  DD DSN={load_dsn}(NOPT),DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(CYL,(2,1,5)),
//            DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(5,2))
//SYSPRINT DD SYSOUT=*
//LIST     EXEC PGM=AMBLIST,COND=(4,LT,LKED)
//SYSLIB   DD DSN={load_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTLOAD OUTPUT=BOTH,MEMBER=NOPT
/*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    spool = res.spool
    out = os.path.join(args.work, "iewl_oracle.txt")
    with open(out, "w") as fp:
        fp.write(spool)
    print(f"\n=== {res.jobname} {res.jobid} status={res.status} ===")
    print(f"  full spool -> {out}")

    # echo the discriminating lines: IEWL control records + CCWs + module length
    print("\n--- IEWL member structure (RECORD/CCW/CONTROL/TEXT/LENGTH) ---")
    for ln in spool.splitlines():
        s = ln.rstrip()
        if any(k in s for k in ("RECORD#", "CCW ", "T E X T", "CONTROL SIZE",
                                "LENGTH OF LOAD MODULE", "NOPTEST", "NOPSEC2",
                                "ESD SIZE", "IEW0", "IEB147I", "RETURN CODE",
                                "AUTHORIZATION CODE", "ATTRIBUTES")):
            print("  " + s)


if __name__ == "__main__":
    main()
