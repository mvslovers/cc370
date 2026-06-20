#!/usr/bin/env python3
"""IEWL oracle: how does IEWL split a SINGLE CSECT larger than MAXTEXT into
multiple control+text records?

ld370 used to emit one oversized text record for a section > MAXTEXT (18432) --
intra-section split was not implemented -- which produced an oversized unloaded
block and made RECV370 abend U0200-13 .RECVBLK (and the IEBCOPY reload could not
hold the block either).  This oracle pins the exact layout to reproduce: link one
40000-byte CSECT with real IEWL, AMBLIST LISTLOAD it, and dump every control
record's CCW (load addr / flags / count) + ID/length list.

Result (the layout ld370 now matches): a 40000-byte CSECT becomes three records
  CCW 06000000 40004800  id (1, 4800)   -> 18432 B at load 0
  CCW 06004800 40004800  id (1, 4800)   -> 18432 B at load 18432
  CCW 06009000 40000C40  id (1, 0C40)   ->  3136 B at load 36864   (0D = MODEND)
i.e. split at MAXTEXT, each control record carries the section's PARTIAL length.

Usage:  python3 ld/tests/run_iewl_bigsect.py [--size 40000]
"""
import os
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as", "as370")
WORK = "/tmp/iewlbig"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--size", type=int, default=40000, help="single-CSECT byte size (> MAXTEXT)")
    args = ap.parse_args()
    size = args.size
    os.makedirs(WORK, exist_ok=True)

    src = (
        "BIGSECT  CSECT\n"
        f"BIGENT   DC    {(size - 4) // 2}XL2'1811'   {size - 4}B of LR R1,R1 (NOP)\n"
        "         SR    15,15\n"
        "         BR    14\n"
        "         END   BIGENT\n"
    )
    asm = os.path.join(WORK, "big.s")
    open(asm, "w").write(src)
    obj = os.path.join(WORK, "big.o")
    subprocess.run([AS370, "-o", obj, asm], check=True)
    objbytes = open(obj, "rb").read()
    print(f"[obj] {len(objbytes)} bytes, single CSECT BIGSECT len={size}")

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig
    from mbt.jcl import jobcard
    from mbt.mvsmf import MvsMFClient

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    obj_dsn = f"{hlq}.BIGORC.OBJ"
    load_dsn = f"{hlq}.BIGORC.LOAD"
    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port, user=cfg.mvs_user, password=cfg.mvs_pass)
    for dsn in (obj_dsn, load_dsn):
        try:
            client.delete_dataset(dsn)
        except Exception:
            pass
    client.create_dataset(obj_dsn, dsorg="PS", recfm="FB", lrecl=80, blksize=3120, space=["TRK", 60, 30])
    client.upload_binary(obj_dsn, objbytes)

    jc = jobcard("BIGORC", cfg.jes_jobclass, cfg.jes_msgclass, "IEWL BIGSECT ORACLE")
    jcl = f"""{jc}
//LKED     EXEC PGM=IEWL,PARM='LIST,MAP,XREF,NCAL,RENT,REUS'
//SYSLIN   DD DSN={obj_dsn},DISP=SHR
//SYSLMOD  DD DSN={load_dsn}(BIG),DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(CYL,(3,1,5)),
//            DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(5,2))
//SYSPRINT DD SYSOUT=*
//LIST     EXEC PGM=AMBLIST,COND=(4,LT,LKED)
//SYSLIB   DD DSN={load_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTLOAD OUTPUT=MODLIST,MEMBER=BIG
/*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    open(f"{WORK}/iewl_big.txt", "w").write(res.spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} -> {WORK}/iewl_big.txt ===")
    for ln in res.spool.splitlines():
        s = ln.rstrip()
        if any(k in s for k in ("RECORD#", "CCW ", "CONTROL SIZE", "CESD#", "LENGTH OF LOAD",
                                "BIGSECT", "T E X T", "ESD SIZE", "IEW0", "RETURN CODE")):
            print("  " + s)


if __name__ == "__main__":
    main()
