#!/usr/bin/env python3
"""Capture a REAL 3350 two-member IEBCOPY UNLOAD oracle.

The positive control the host-side unload simulator never had.  Builds two tiny
members (E2EA -> RC 7, E2EB -> RC 3 -- the same pair run_2mem_mvs.py installs),
links each into ONE load library with REAL IEWL, IEBCOPY-UNLOADs the library to a
sequential dataset, then binary-downloads the unload image.  mvsMF binary GET on
the RECFM=VS unload returns the clean logical-record stream (proven by the
single-member e2e.iebcopy-unload.bin capture), so the download needs no special
framing.

The objects are assembled host-side with as370 (byte-identical to IFOX for these
macro-free modules; same path run_iewl_oracle.py uses) so MVS does only the parts
the host can't: IEWL's real on-disk member layout and IEBCOPY's unload geometry --
which is exactly what we need to learn.  The unload geometry depends on the block
count, not on who assembled the member, so an as370 object yields the same oracle.

The captured bytes are the byte oracle for how IEBCOPY packs TWO members:
member-boundary layout (do members share a track? continuous R?), where each
DL=0 EOF sits, and the directory TTRs.  decode_2mem_oracle.py reads it; the
emit_unload rewrite reproduces it.

Usage:
  python3 ld370/tests/run_2mem_oracle.py
    -> writes ld370/tests/fixtures/e2e2.iebcopy-unload.bin
"""
import os
import re
import sys
import subprocess

REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
AS370 = os.path.join(REPO, "as370", "as370")
FIXTURES = os.path.join(REPO, "ld370", "tests", "fixtures")
WORK = "/tmp/e2e2orc"

# (member, return code) -- distinct RCs, the same pair run_2mem_mvs.py uses.
MEMBERS = [("E2EA", 7), ("E2EB", 3)]


def sh(cmd, **kw):
    print("+ " + " ".join(cmd))
    return subprocess.run(cmd, check=True, **kw)


def build_obj(name, rc):
    """Assemble a minimal runnable member (LA 15,rc ; BR 14) host-side."""
    src = os.path.join(WORK, name + ".s")
    obj = os.path.join(WORK, name + ".o")
    with open(src, "w") as fp:
        fp.write(f"{name:<8} CSECT\n         LA    15,{rc}\n"
                 f"         BR    14\n         END   {name}\n")
    sh([AS370, "-o", obj, src])
    return open(obj, "rb").read()


def main():
    os.makedirs(WORK, exist_ok=True)
    objs = [(n, build_obj(n, rc)) for n, rc in MEMBERS]

    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    os.chdir("/Users/mike/repos/mvs/crent370")
    from mbt.config import MbtConfig          # noqa: E402
    from mbt.jcl import jobcard               # noqa: E402
    from mbt.mvsmf import MvsMFClient         # noqa: E402

    cfg = MbtConfig()
    hlq = cfg.get("mvs.hlq")
    load_dsn = f"{hlq}.E2E2ORC.LOAD"
    pdsu_dsn = f"{hlq}.E2E2ORC.PDSU"
    obj_dsn = {n: f"{hlq}.E2E2ORC.OBJ{n[-1]}" for n, _ in MEMBERS}

    client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                         user=cfg.mvs_user, password=cfg.mvs_pass)

    for dsn in [load_dsn, pdsu_dsn, *obj_dsn.values()]:
        try:
            client.delete_dataset(dsn)
            print(f"  deleted pre-existing {dsn}")
        except Exception:
            pass

    for name, blob in objs:
        dsn = obj_dsn[name]
        client.create_dataset(dsn, dsorg="PS", recfm="FB", lrecl=80,
                              blksize=3120, space=["TRK", 5, 5])
        client.upload_binary(dsn, blob)
        print(f"  uploaded {name}.o ({len(blob)} B) -> {dsn}")

    jc = jobcard("E2E2ORC", cfg.jes_jobclass, cfg.jes_msgclass, "2MEM UNLOAD ORACLE")
    steps = [jc, f"""//ALLOC    EXEC PGM=IEFBR14
//LOADLIB  DD DSN={load_dsn},DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(CYL,(2,1,5)),
//            DCB=(RECFM=U,BLKSIZE=19069)"""]

    for name, _ in MEMBERS:
        steps.append(f"""//LKED{name[-1]}   EXEC PGM=IEWL,PARM='LIST,MAP,XREF,RENT,REUS',
//            COND=(4,LT)
//SYSLIN   DD DSN={obj_dsn[name]},DISP=SHR
//SYSLMOD  DD DSN={load_dsn}({name}),DISP=SHR
//SYSUT1   DD UNIT=VIO,SPACE=(CYL,(2,1))
//SYSPRINT DD SYSOUT=*""")

    steps.append(f"""//UNLOAD   EXEC PGM=IEBCOPY,COND=(4,LT)
//SYSPRINT DD SYSOUT=*
//SYSUT3   DD UNIT=SYSDA,SPACE=(TRK,(2,2))
//SYSUT4   DD UNIT=SYSDA,SPACE=(TRK,(2,2))
//IN       DD DSN={load_dsn},DISP=SHR
//OUT      DD DSN={pdsu_dsn},DISP=(NEW,CATLG),
//            UNIT=SYSDA,SPACE=(TRK,(5,5))
//SYSIN    DD *
  COPY INDD=IN,OUTDD=OUT
/*
//""")
    jcl = "\n".join(steps) + "\n"

    res = client.submit_jcl(jcl, wait=True, timeout=240)
    spool = res.spool
    with open(os.path.join(WORK, "oracle_spool.txt"), "w") as fp:
        fp.write(spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} ===")
    for ln in spool.splitlines():
        if re.search(r"IEB1|IEB0|COND CODE|ABEND|COPIED|FOLLOWING MEMBERS|"
                     r"RECFM|LRECL|BLKSIZE|DSORG|IEW0|RETURN CODE", ln):
            print("  " + ln.rstrip())

    if res.status != "CC":
        sys.exit(f"job did not complete cleanly (status={res.status}) -- see spool")

    try:
        for d in client.list_datasets(pdsu_dsn):
            if d.get("dsname", "").upper() == pdsu_dsn:
                print(f"  PDSU DCB: recfm={d.get('recfm')} lrecl={d.get('lrecl')} "
                      f"blksize={d.get('blksize')} dsorg={d.get('dsorg')}")
    except Exception as e:
        print(f"  (dcb query: {e})")

    u = client._request("GET", f"/restfiles/ds/{pdsu_dsn}",
                        accept="application/octet-stream",
                        extra_headers={"X-IBM-Data-Type": "binary"})
    out = os.path.join(FIXTURES, "e2e2.iebcopy-unload.bin")
    with open(out, "wb") as fp:
        fp.write(u)
    print(f"\n  unload image: {len(u)} bytes -> {out}")
    print("  next: python3 ld370/tests/decode_2mem_oracle.py")


if __name__ == "__main__":
    main()
