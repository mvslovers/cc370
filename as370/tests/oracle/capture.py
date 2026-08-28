#!/usr/bin/env python3
"""Assemble a module with the REAL IFOX00 on an MVS 3.8j guest and bring the
result back: the object deck byte-for-byte, and the SYSPRINT listing.

This is how the reference decks in tests/ref/ and the listings in
tests/listref/ are produced when nobody else can supply them. as370's whole
claim is byte-identity to IFOX00, so a construct the ecosystem corpus does not
contain has no oracle until one is made -- floating point (#53) was the first
time that was true of an entire feature.

    python3 capture.py SOURCE.s --deck out.obj --listing out.txt

Connection: the mvsMF REST API, from an mbt-style .env (MBT_MVS_HOST / _PORT /
_USER / _PASS, MBT_JES_JOBCLASS / _MSGCLASS). Point AS370_MVS_ENV at it; there
is no default, because this repo carries no .env of its own.

What it does on the target: submits one job. SYSIN is inline and SYSPRINT goes
to the spool, so nothing is left behind -- except while --deck is asked for,
when SYSPUNCH needs a dataset. That one is created, read back with
X-IBM-Data-Type: binary, and deleted again in the same run.
"""
import argparse
import os
import sys
from pathlib import Path

# mbt carries the mvsMF client; it sits beside this checkout in the ecosystem
# layout. Override with MBT_ROOT if it lives elsewhere.
MBT = os.environ.get("MBT_ROOT", str(Path(__file__).resolve()
                                     .parents[4] / "mbt"))
sys.path.insert(0, str(Path(MBT) / "scripts"))
try:
    from mbt.mvsmf import MvsMFClient
except ImportError:
    sys.exit(f"capture.py: mbt's mvsMF client not found under {MBT}\n"
             f"            set MBT_ROOT=<path to the mbt checkout>")

SCRATCH_SUFFIX = "CC370.ORACLE.OBJ"


def load_env(path):
    env = {}
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip()
    return env


def build_jcl(env, src, scratch, deck):
    """One IFOX00 step. PARM matches tests/listref: the listing is column-exact
    to what the committed references were captured with."""
    parm = "DECK" if deck else "NODECK"
    punch = (f"//SYSPUNCH DD DSN={scratch},DISP=(NEW,CATLG,DELETE),\n"
             f"//             UNIT=SYSDA,SPACE=(TRK,(5,5)),\n"
             f"//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=800)"
             if deck else "//SYSPUNCH DD DUMMY")
    # a leading IEFBR14 clears a scratch dataset left by an interrupted run
    predel = (f"//DEL      EXEC PGM=IEFBR14\n"
              f"//OLD      DD DSN={scratch},DISP=(MOD,DELETE,DELETE),\n"
              f"//             UNIT=SYSDA,SPACE=(TRK,(1,1))\n"
              if deck else "")
    return f"""//ASMORCL  JOB (ACCT),'IFOX ORACLE',CLASS={env.get('MBT_JES_JOBCLASS', 'A')},
//             MSGCLASS={env.get('MBT_JES_MSGCLASS', 'A')},MSGLEVEL=(1,1)
{predel}//ASM      EXEC PGM=IFOX00,
//          PARM='{parm},LIST,NOLOAD,XREF(FULL),RENT'
//SYSLIB   DD DSN=SYS1.MACLIB,DISP=SHR
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSPRINT DD SYSOUT=*
//SYSGO    DD DUMMY
{punch}
//SYSIN    DD *
{src}
/*
//
"""


def sysprint_of(spool):
    """The SYSPRINT DD out of mbt's concatenated spool text."""
    marker = "--- SYSPRINT ---"
    if marker not in spool:
        return spool
    body = spool.split(marker, 1)[1].lstrip("\n")
    end = body.find("\n--- ")
    return body if end < 0 else body[:end]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source")
    ap.add_argument("--deck", help="write IFOX00's object deck here")
    ap.add_argument("--listing", help="write the SYSPRINT listing here")
    args = ap.parse_args()

    envfile = os.environ.get("AS370_MVS_ENV")
    if not envfile:
        sys.exit("capture.py: set AS370_MVS_ENV to an mbt-style .env "
                 "(MBT_MVS_HOST/_PORT/_USER/_PASS)")
    env = load_env(envfile)
    client = MvsMFClient(env["MBT_MVS_HOST"], int(env["MBT_MVS_PORT"]),
                         env["MBT_MVS_USER"], env["MBT_MVS_PASS"])
    scratch = f"{env['MBT_MVS_USER']}.{SCRATCH_SUFFIX}"
    src = Path(args.source).read_text().rstrip("\n")

    # A source line reaching column 72 is a continuation card to IFOX00 -- for
    # COMMENT cards too, which as370 does not enforce. Refuse rather than let
    # the guest flag a fixture nobody meant to continue.
    for n, line in enumerate(src.split("\n"), 1):
        if len(line) > 71 and line[71] != " ":
            print(f"capture.py: line {n} is continued (column 72 is not blank) "
                  f"-- intended?", file=sys.stderr)

    print(f"submitting to {env['MBT_MVS_HOST']}:{env['MBT_MVS_PORT']} "
          f"as {env['MBT_MVS_USER']}")
    res = client.submit_jcl(build_jcl(env, src, scratch, bool(args.deck)),
                            wait=True, timeout=180)
    print(f"job {res.jobname} {res.jobid}  status={res.status}  rc={res.rc}")
    if args.listing:
        Path(args.listing).write_text(sysprint_of(res.spool))
        print(f"listing -> {args.listing}")
    if res.rc != 0:
        sys.exit(f"capture.py: IFOX00 returned {res.rc} -- see the listing")
    if args.deck:
        raw = client._request("GET", f"/restfiles/ds/{scratch}",
                              accept="application/octet-stream",
                              extra_headers={"X-IBM-Data-Type": "binary"})
        Path(args.deck).write_bytes(raw)
        print(f"deck -> {args.deck} ({len(raw)} bytes, "
              f"{len(raw) // 80} cards)")
        client.delete_dataset(scratch)
        print(f"scratch dataset {scratch} deleted")


main()
