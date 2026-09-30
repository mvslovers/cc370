#!/usr/bin/env python3
"""IEWL oracle for cc370#102: what does the linkage editor do with a CSECT
name that a later EXPLICIT object defines again?

One job, temporary data sets only -- nothing survives it.  IFOX00 assembles
the sources in the job, IEWL links them, AMBLIST lists the result.  Read the
MAP/XREF and the AMBLIST text/RLD, not the RC.

Objects (assembler layout in brackets):
 OA   OA [0,8] = A(QQ),A(OA);  QQ [8,4] = C'QQ1 '           <- first QQ
 OB   OB [0,8] = A(QQ),A(OC);  QQ [8,x20] = A(OB),A(QQ),
      QE (ENTRY) C'QQ2',4F'0';  OC [x28,8] = C'OC  ',A(QE)   <- QQ again, MID-object
 OD   OD [0,8] = V(QE),V(OC)

 TE   SYSLIN = OA, OB, OD.  Predictions:
        delete + compact : OA 00, QQ 08/4, OB 10, OC 18, OD 20, total x28
        delete, keep hole: OC at x38 (OB's layout kept, its QQ text dropped)
        last one wins    : QQ at x18/x20 (ld370 before #102)
      and, whichever holds: where OB's A(QQ) binds, whether the RLDs inside
      the dropped QQ survive, and what becomes of QE (defined only inside it).
 TE2  SYSLIN = OB, OA, OD: the dropped QQ is now OA's, at the END of its
      object.  delete + compact: OB 00, QQ 08/x20, OC 28, OA 30, OD 38.

Measured on MVSCE-LAB, JOB01409 (MAP/XREF + AMBLIST LISTLOAD):

 TE   OA 00/8, QQ 08/4, OB 10/8, OC 18/8, OD 20/8, total x28 -- delete +
      compact.  OB's QQ contributes no text and no space, and OC moves up
      to the next doubleword after OB.  No message about the duplicate.
      - OB's A(QQ) = 08: a reference to the dropped section binds to the
        kept one.
      - OC's A(QE) = 10: an adcon relative to the dropped section keeps its
        offset inside it and is relocated against the kept one -- so it now
        points into OB.  Silently.
      - The two RLDs located inside the dropped QQ are gone.
      - QE, an ENTRY of the dropped QQ, is gone with it: OD's V(QE) is
        IEW0461 (unresolved, NCAL), value 0, step RC 4.
 TE2  OB 00/8, QQ 08/x20 (QE at 10), OC 28/8, OA 30/8, OD 38/8, total x40.
      OA's QQ, at the end of its object, is dropped; OA's A(QQ) = 08.
      OD's V(QE) = 10, RC 0.

Usage:
  python3 run_iewl_dupcsect_oracle.py            # print the JCL, submit nothing
  python3 run_iewl_dupcsect_oracle.py --submit   # submit to MVSCE-LAB (:8082)
"""
import argparse
import os
import re
import sys

WORK = "/tmp/iewldupcsect"
HOST, PORT = "mvsdev.lan", 8082          # MVSCE-LAB: submit=true in systems.json

SRC = {
    "OA": ["OA       CSECT", "         DC    A(QQ)", "         DC    A(OA)",
           "QQ       CSECT", "         DC    CL4'QQ1'"],
    "OB": ["OB       CSECT", "         DC    A(QQ)", "         DC    A(OC)",
           "QQ       CSECT", "         ENTRY QE", "         DC    A(OB)",
           "         DC    A(QQ)", "QE       DC    CL8'QQ2'",
           "         DC    4F'0'",
           "OC       CSECT", "         DC    CL4'OC'", "         DC    A(QE)"],
    "OD": ["OD       CSECT", "         DC    V(QE)", "         DC    V(OC)"],
}

TMP = "UNIT=SYSDA,SPACE=(CYL,(1,1))"
FB = "DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)"


def asm_step(obj):
    # one data set per object: a passed temporary data set may be referenced
    # only once per step (IEF212I, JOB01406), and SYSLIN concatenates them
    lines = [f"//A{obj:<7} EXEC PGM=IFOX00,PARM='OBJ,NODECK'",
             "//SYSLIB   DD DSN=SYS1.MACLIB,DISP=SHR",
             f"//SYSUT1   DD {TMP}",
             f"//SYSUT2   DD {TMP}",
             f"//SYSUT3   DD {TMP}",
             "//SYSPRINT DD SYSOUT=*",
             f"//SYSGO    DD DSN=&&{obj},DISP=(NEW,PASS),",
             f"//            {FB},",
             "//            UNIT=SYSDA,SPACE=(TRK,(2,1))",
             "//SYSIN    DD *"]
    lines += SRC[obj] + ["         END", "/*"]
    return lines


def link_step(step, objs):
    lines = [f"//{step:<8} EXEC PGM=IEWL,PARM='LIST,MAP,XREF,LET,NCAL'",
             f"//SYSUT1   DD {TMP}",
             "//SYSPRINT DD SYSOUT=*",
             f"//SYSLMOD  DD DSN=&&OUT({step}),DISP=(OLD,PASS)"]
    for i, obj in enumerate(objs):
        lines.append(f"//{'SYSLIN' if i == 0 else '':<8} DD DSN=&&{obj},DISP=(OLD,PASS)")
    return lines


def build_jcl():
    j = ["//DUPCSORC JOB (A),'IEWL DUP CSECT',CLASS=A,MSGCLASS=H,",
         "//             MSGLEVEL=(1,1),NOTIFY=&SYSUID",
         "//* cc370#102: IEWL with a CSECT defined by two explicit objects",
         "//ALLOC    EXEC PGM=IEFBR14",
         "//OUT      DD DSN=&&OUT,DISP=(NEW,PASS),DCB=(RECFM=U,BLKSIZE=6144),",
         "//            UNIT=SYSDA,SPACE=(TRK,(15,5,10))"]
    for obj in SRC:
        j += asm_step(obj)
    j += link_step("TE", ["OA", "OB", "OD"])
    j += link_step("TE2", ["OB", "OA", "OD"])
    j += ["//LIST     EXEC PGM=AMBLIST",
          "//SYSPRINT DD SYSOUT=*",
          "//SYSLIB   DD DSN=&&OUT,DISP=(OLD,PASS)",
          "//SYSIN    DD *",
          " LISTLOAD OUTPUT=BOTH,MEMBER=(TE,TE2)",
          "/*",
          "//"]
    return j


def gate(lines):
    bad = [(i + 1, ln) for i, ln in enumerate(lines) if len(ln) > 71]
    for n, ln in bad:
        print(f"TOO LONG line {n}: {ln}", file=sys.stderr)
    return not bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--submit", action="store_true")
    ap.add_argument("--out", default=os.path.join(WORK, "spool.txt"))
    args = ap.parse_args()

    jcl = build_jcl()
    if not gate(jcl):
        return 1
    if not args.submit:
        print("\n".join(jcl))
        return 0

    sys.path.insert(0, "/Users/mike/repos/mvs/mvs38src/tools")
    from creds import pair                          # noqa: E402
    user, pw = pair("MVSCE-LAB")
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    from mbt.mvsmf import MvsMFClient               # noqa: E402
    client = MvsMFClient(host=HOST, port=PORT, user=user, password=pw)
    res = client.submit_jcl("\n".join(jcl) + "\n", wait=True, timeout=600)
    with open(args.out, "w") as fp:
        fp.write(res.spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} -> {args.out}")
    for ln in res.spool.splitlines():
        if re.search(r"IEW\d|IEF142I|IEF472I|IEF212I|ABEND|COMPLETION CODE|IFO\d", ln):
            print("  " + ln.rstrip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
