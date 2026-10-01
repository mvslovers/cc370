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

--asa FILE keeps the carriage control. The spool route hands the listing back
without column 1, so a SPACE or a double-spaced line cannot be told from the
lines around it (#623). With --asa, SYSPRINT goes to a second scratch dataset,
RECFM=FBA LRECL=121 -- the way mvs38src's ifox_run.py captures its listings --
is read back with column 1 intact and deleted. --listing is then derived from
it by dropping column 1, which is the same text the spool gives.
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
LISTING_SUFFIX = "CC370.ORACLE.LST"


def load_env(path):
    env = {}
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        env[k.strip()] = v.strip()
    return env


def build_jcl(env, src, scratch, deck, syslib=None, xref="FULL", lst=None):
    """One IFOX00 step. PARM matches tests/listref: the listing is column-exact
    to what the committed references were captured with."""
    # SYSLIB is a concatenation: the first DD carries the name, the rest are
    # unnamed continuations. A module that needs AMODGEN or one of the recovered
    # private macro libraries assembles to a different deck -- or not at all --
    # without them, so a listing captured with the wrong search order is not
    # comparable to a host run that used a different one.
    libs = list(syslib) if syslib else ["SYS1.MACLIB"]
    syslib_dd = "\n".join(
        (f"//SYSLIB   DD DSN={d},DISP=SHR" if i == 0 else f"//         DD DSN={d},DISP=SHR")
        for i, d in enumerate(libs))
    parm = "DECK" if deck else "NODECK"
    punch = (f"//SYSPUNCH DD DSN={scratch},DISP=(NEW,CATLG,DELETE),\n"
             f"//             UNIT=SYSDA,SPACE=(TRK,(5,5)),\n"
             f"//             DCB=(RECFM=FB,LRECL=80,BLKSIZE=800)"
             if deck else "//SYSPUNCH DD DUMMY")
    # a leading IEFBR14 clears a scratch dataset left by an interrupted run
    olds = ([scratch] if deck else []) + ([lst] if lst else [])
    predel = ("//DEL      EXEC PGM=IEFBR14\n" + "".join(
              f"//OLD{k}     DD DSN={d},DISP=(MOD,DELETE,DELETE),\n"
              f"//             UNIT=SYSDA,SPACE=(TRK,(1,1))\n" for k, d in enumerate(olds))
              if olds else "")
    sysprint = (f"//SYSPRINT DD DSN={lst},DISP=(NEW,CATLG,DELETE),\n"
                f"//             UNIT=SYSDA,SPACE=(TRK,(30,30)),\n"
                f"//             DCB=(RECFM=FBA,LRECL=121,BLKSIZE=1210)"
                if lst else "//SYSPRINT DD SYSOUT=*")
    return f"""//ASMORCL  JOB (ACCT),'IFOX ORACLE',CLASS={env.get('MBT_JES_JOBCLASS', 'A')},
//             MSGCLASS={env.get('MBT_JES_MSGCLASS', 'A')},MSGLEVEL=(1,1)
{predel}//ASM      EXEC PGM=IFOX00,
//          PARM='{parm},LIST,NOLOAD,XREF({xref}),RENT'
{syslib_dd}
//SYSUT1   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT2   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
//SYSUT3   DD UNIT=SYSDA,SPACE=(CYL,(1,1))
{sysprint}
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
    ap.add_argument("--syslib", action="append", metavar="DSN",
                    help="SYSLIB dataset, repeatable and concatenated in the order given "
                         "(default: SYS1.MACLIB). Must match the host -I search order, "
                         "or the two assemblies are not comparable.")
    ap.add_argument("--deck-on-error", action="store_true",
                    help="fetch --deck even when IFOX00 returns non-zero. A fixture "
                         "written to provoke a diagnostic assembles at rc 4 or 8 BY "
                         "DESIGN and still punches a deck; without this the deck is "
                         "thrown away and only the listing survives.")
    ap.add_argument("--asa", metavar="FILE",
                    help="write the listing WITH its carriage-control column here "
                         "(SYSPRINT to a scratch FBA dataset); --listing is then "
                         "derived from it")
    ap.add_argument("--xref", choices=("full", "short"), default="full",
                    help="XREF(FULL) (default, what tests/listref was captured with) or "
                         "XREF(SHORT), which as370 writes for --xref=short")
    args = ap.parse_args()

    envfile = os.environ.get("AS370_MVS_ENV")
    if not envfile:
        sys.exit("capture.py: set AS370_MVS_ENV to an mbt-style .env "
                 "(MBT_MVS_HOST/_PORT/_USER/_PASS)")
    env = load_env(envfile)
    client = MvsMFClient(env["MBT_MVS_HOST"], int(env["MBT_MVS_PORT"]),
                         env["MBT_MVS_USER"], env["MBT_MVS_PASS"])
    scratch = f"{env['MBT_MVS_USER']}.{SCRATCH_SUFFIX}"
    lst = f"{env['MBT_MVS_USER']}.{LISTING_SUFFIX}" if args.asa else None
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
    res = client.submit_jcl(build_jcl(env, src, scratch, bool(args.deck), args.syslib, args.xref.upper(), lst),
                            wait=True, timeout=180)
    print(f"job {res.jobname} {res.jobid}  status={res.status}  rc={res.rc}")
    if lst:
        try:
            raw = client._request("GET", f"/restfiles/ds/{lst}", accept="text/plain")
            text = raw.decode("latin-1") if isinstance(raw, bytes) else raw
        except Exception as exc:                          # noqa: BLE001
            text = None
            print(f"capture.py: no listing in {lst} ({exc})", file=sys.stderr)
        try:
            client.delete_dataset(lst)
            print(f"scratch dataset {lst} deleted")
        except Exception as exc:                          # noqa: BLE001 - best effort
            print(f"capture.py: could not delete {lst}: {exc}", file=sys.stderr)
        if text is not None:
            recs = text.rstrip("\n").split("\n")
            Path(args.asa).write_text("\n".join(recs) + "\n")
            print(f"asa listing -> {args.asa} ({len(recs)} records)")
            if args.listing:
                Path(args.listing).write_text("\n".join(r[1:] for r in recs) + "\n")
                print(f"listing -> {args.listing} (column 1 dropped)")
    elif args.listing:
        Path(args.listing).write_text(sysprint_of(res.spool))
        print(f"listing -> {args.listing}")
    failed = res.rc != 0
    if failed and not (args.deck and args.deck_on_error):
        # The scratch dataset is CATLG'd by the step that punched into it, so a
        # bare exit here leaves it behind and the NEXT run's IEFBR14 has to clear
        # it. Delete it on the way out.
        if args.deck:
            try:
                client.delete_dataset(scratch)
            except Exception as exc:                      # noqa: BLE001 - best effort
                print(f"capture.py: could not delete {scratch}: {exc}", file=sys.stderr)
        sys.exit(f"capture.py: IFOX00 returned {res.rc} -- see the listing "
                 f"(pass --deck-on-error to keep the deck anyway)")
    if args.deck:
        try:
            raw = client._request("GET", f"/restfiles/ds/{scratch}",
                                  accept="application/octet-stream",
                                  extra_headers={"X-IBM-Data-Type": "binary"})
        except Exception as exc:                          # noqa: BLE001
            # A severe enough error ends the assembly before anything is punched;
            # the dataset then holds nothing, or was never catalogued.
            sys.exit(f"capture.py: no deck to read from {scratch} ({exc}) -- "
                     f"IFOX00 rc={res.rc}, the listing is all there is")
        Path(args.deck).write_bytes(raw)
        print(f"deck -> {args.deck} ({len(raw)} bytes, "
              f"{len(raw) // 80} cards)")
        client.delete_dataset(scratch)
        print(f"scratch dataset {scratch} deleted")
        if failed:
            # Expected, and the caller said so -- but never let it read as clean.
            print(f"capture.py: IFOX00 returned {res.rc}; deck captured anyway "
                  f"(--deck-on-error)")


main()
