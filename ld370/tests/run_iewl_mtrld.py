#!/usr/bin/env python3
"""IEWL oracle: how does IEWL size/place RLD records when there are many?

ld370 used to emit ALL of a module's RLD items in one RLD record. Program fetch
reads RLD records into a 256-byte buffer (IEWFETCH FTRBUF); an oversized RLD
record overflows it and fetch relocates garbage -> S106 reason 0E. The fixture
RLDs are tiny (one record) so they never showed it; a real C program (t1, 836
items / 5484 B) did.

This oracle builds a module with many A(SECTA) adcons (=> a big RLD), links it
with real IEWL, AMBLISTs it, and runs it. Result: IEWL splits RLD data into
records of <= 236 bytes (16-byte header + 236 = 252 <= the 256 buffer), all
byte0=02 except the last (0E = RLD + MODEND), and the module runs RC=0. ld370
now matches.

Usage:  python3 ld/tests/run_iewl_mtrld.py [--adcons 1500]
"""
import os
import sys
import argparse
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
WORK = "/tmp/iewlmtrld"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--adcons", type=int, default=1500, help="number of A(SECTA) adcons (RLD items)")
    args = ap.parse_args()
    os.makedirs(WORK, exist_ok=True)
    src = (
        "SECTA    CSECT\n"
        "ENTA     SR    15,15\n"
        "         BR    14\n"
        "SECTB    CSECT\n"
        f"         DC    {args.adcons}A(SECTA)\n"
        "         END   ENTA\n"
    )
    asm = os.path.join(WORK, "mt.s"); open(asm, "w").write(src)
    obj = os.path.join(WORK, "mt.o")
    subprocess.run([AS370, "-o", obj, asm], check=True)
    print(f"[obj] {os.path.getsize(obj)} bytes, {args.adcons} adcons")

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig
    from mbt.jcl import jobcard
    from mbt.mvsmf import MvsMFClient
    cfg = MbtConfig(); hlq = cfg.get("mvs.hlq")
    obj_dsn = f"{hlq}.MTRLD.OBJ"; load_dsn = f"{hlq}.MTRLD.LOAD"
    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port, user=cfg.mvs_user, password=cfg.mvs_pass)
    for dsn in (obj_dsn, load_dsn):
        try: client.delete_dataset(dsn)
        except Exception: pass
    client.create_dataset(obj_dsn, dsorg="PS", recfm="FB", lrecl=80, blksize=3120, space=["TRK", 30, 15])
    client.upload_binary(obj_dsn, open(obj, "rb").read())

    jc = jobcard("MTRLD", cfg.jes_jobclass, cfg.jes_msgclass, "IEWL RLD-SIZE ORACLE")
    jcl = f"""{jc}
//LKED     EXEC PGM=IEWL,PARM='LIST,MAP,XREF,NCAL,RENT,REUS'
//SYSLIN   DD DSN={obj_dsn},DISP=SHR
//SYSLMOD  DD DSN={load_dsn}(MT),DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(CYL,(2,1,5)),
//            DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(5,2))
//SYSPRINT DD SYSOUT=*
//LIST     EXEC PGM=AMBLIST,COND=(20,LT,LKED)
//SYSLIB   DD DSN={load_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
 LISTLOAD OUTPUT=MODLIST,MEMBER=MT
/*
//RUN      EXEC PGM=MT,COND=(20,LT,LKED)
//STEPLIB  DD DSN={load_dsn},DISP=SHR
//SYSPRINT DD SYSOUT=*
//
"""
    res = client.submit_jcl(jcl, wait=True, timeout=180)
    open(f"{WORK}/iewl_mt.txt", "w").write(res.spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} -> {WORK}/iewl_mt.txt ===")
    for ln in res.spool.splitlines():
        s = ln.rstrip()
        if any(k in s for k in ("RLD SIZE", "TYPE 0", "RECORD#", "COND CODE", "ABEND", "COMPLETION")):
            print("  " + s)


if __name__ == "__main__":
    main()
