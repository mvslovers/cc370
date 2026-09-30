"""IEWL oracle for cc370#8: how does the linkage editor's automatic library
call behave when a symbol has more than one possible definer?

One job, temporary data sets only (&&OBJ, &&OBJ2, &&LIBA, &&LIBB, &&OUT) --
nothing survives it.  Sources are assembled by IFOX00 in the job and the
libraries are built by IEWL NCAL, so every byte is IBM's.  Read the MAP/XREF,
not the RC.

Measured on MVSCE-LAB, JOB01408 (JOB01407 identical except TC, whose MC2 was
lost to the IFOX00 BATCH attempt):

 TA1/TA2  MA refs XX; LIBA(XX) is 4 bytes + XXA, LIBB(XX) 16 bytes + XXB.
          SYSLIB=LIBA,LIBB -> XX 4/XXA; SYSLIB=LIBB,LIBA -> XX 16/XXB.
          First library in the concatenation wins, SILENTLY, RC 0.
 TB       MB refs YLD, an ENTRY of member YMEM with no alias.
          IEW0132 unresolved, RC 8: autocall searches member names and
          aliases, never the ESD of a member.
 TB2      MZ refs ZLD, ENTRY of ZMEM WITH ALIAS ZLD -> resolved (control).
 TC       explicit MC (ENTRY DUPL at MC+8, refs WW) + MC2 (refs DUPL);
          autocall pulls WW, which also defines ENTRY DUPL.
          IEW0241 WARNING ... DOUBLY DEFINED, RC 4; first definition kept,
          MC2's DUPL binds to MC+8.
 TC2      explicit MD (+ CSECT QQ, 4 bytes); autocall pulls RR, which also
          carries CSECT QQ (24 bytes).  First QQ kept, SILENTLY, RC 0,
          total length 0x18.
 BD       TT linked into LIBA with ALIAS XX while member XX exists:
          IEW0543 IDENTICAL NAME IN DIRECTORY, RC 12, NOT EXECUTABLE.
 TD       MA against LIBA after BD -> XX 4/XXA: the old member stands.

So IEWL cannot meet the case #8 is about -- two members of one library
defining the resolved name -- because a PDS directory holds each name once
and BD shows IEWL refusing the collision when the library is built.  ld370
meets it because it resolves through the archive's ESD index (TB differs).

Usage:
  python3 run_iewl_autocall_oracle.py        # print the JCL, submit nothing
  python3 run_iewl_autocall_oracle.py --submit # submit to MVSCE-LAB (:8082)
"""
import argparse
import os
import re
import sys

WORK = "/tmp/iewlautocall"
HOST, PORT = "mvsdev.lan", 8082          # MVSCE-LAB: submit=true in systems.json

SRC = {
    "XA":  ["XX       CSECT", "         ENTRY XXA", "XXA      DC    F'1'"],
    "XB":  ["XX       CSECT", "         ENTRY XXB", "         DC    3F'2'",
            "XXB      DC    F'2'"],
    "YM":  ["YMEM     CSECT", "         ENTRY YLD", "         DC    F'3'",
            "YLD      DC    F'3'"],
    "ZM":  ["ZMEM     CSECT", "         ENTRY ZLD", "         DC    F'4'",
            "ZLD      DC    F'4'"],
    "WW":  ["WW       CSECT", "         ENTRY DUPL", "         DC    F'5'",
            "DUPL     DC    F'5'"],
    "RR":  ["RR       CSECT", "         DC    F'6'", "QQ       CSECT",
            "         DC    6F'6'"],
    "TT":  ["TT       CSECT", "         ENTRY XX", "         DC    7F'7'",
            "XX       DC    F'7'"],
    "MA":  ["MA       CSECT", "         DC    V(XX)"],
    "MB":  ["MB       CSECT", "         DC    V(YLD)"],
    "MZ":  ["MZ       CSECT", "         DC    V(ZLD)"],
    "MC":  ["MC       CSECT", "         ENTRY DUPL", "         DC    V(WW)",
            "         DC    F'0'", "DUPL     DC    F'8'"],
    "MC2": ["MC2      CSECT", "         DC    V(DUPL)"],
    "MD":  ["MD       CSECT", "         DC    V(RR)", "QQ       CSECT",
            "         DC    F'9'"],
}

TMP = "UNIT=SYSDA,SPACE=(CYL,(1,1))"


def dd_old(name, member=None):
    m = f"({member})" if member else ""
    return f"DSN=&&{name}{m},DISP=(OLD,PASS)"


def asm_step(obj, ds="OBJ"):
    """A passed temporary data set may be referenced only once per step
    (IEF212I on the second reference, JOB01406), and IFOX00 has no BATCH
    option (IFO258, severity 16, JOB01407) -- so MC2, which TC links beside
    MC, goes into a data set of its own."""
    lines = [f"//A{obj:<7} EXEC PGM=IFOX00,PARM='OBJ,NODECK'",
             "//SYSLIB   DD DSN=SYS1.MACLIB,DISP=SHR",
             f"//SYSUT1   DD {TMP}",
             f"//SYSUT2   DD {TMP}",
             f"//SYSUT3   DD {TMP}",
             "//SYSPRINT DD SYSOUT=*",
             f"//SYSGO    DD {dd_old(ds, obj)}",
             "//SYSIN    DD *"]
    lines += SRC[obj] + ["         END", "/*"]
    return lines


def lib_step(step, obj, lib, name, alias=None):
    lines = [f"//{step:<8} EXEC PGM=IEWL,PARM='LIST,XREF,NCAL,LET'",
             f"//SYSUT1   DD {TMP}",
             "//SYSPRINT DD SYSOUT=*",
             f"//SYSLMOD  DD {dd_old(lib)}",
             f"//SYSLIN   DD {dd_old('OBJ', obj)}",
             "//         DD *"]
    if alias:
        lines.append(f" ALIAS {alias}")
    lines += [f" NAME {name}", "/*"]
    return lines


def link_step(step, objs, libs):
    lines = [f"//{step:<8} EXEC PGM=IEWL,PARM='LIST,MAP,XREF,LET'",
             f"//SYSUT1   DD {TMP}",
             "//SYSPRINT DD SYSOUT=*",
             f"//SYSLMOD  DD {dd_old('OUT', step)}"]
    for i, lib in enumerate(libs):
        lines.append(f"//{'SYSLIB' if i == 0 else '':<8} DD {dd_old(lib)}")
    for i, obj in enumerate(objs):
        ds = "OBJ2" if obj == "MC2" else "OBJ"
        lines.append(f"//{'SYSLIN' if i == 0 else '':<8} DD {dd_old(ds, obj)}")
    return lines


def build_jcl():
    pds_fb = "DCB=(RECFM=FB,LRECL=80,BLKSIZE=3120)"
    pds_u = "DCB=(RECFM=U,BLKSIZE=6144)"
    j = ["//ACALLORC JOB (A),'IEWL AUTOCALL',CLASS=A,MSGCLASS=H,",
         "//             MSGLEVEL=(1,1),NOTIFY=&SYSUID",
         "//* cc370#8: IEWL automatic library call with several definers",
         "//ALLOC    EXEC PGM=IEFBR14",
         "//OBJ      DD DSN=&&OBJ,DISP=(NEW,PASS),",
         f"//            {pds_fb},",
         "//            UNIT=SYSDA,SPACE=(TRK,(15,5,10))"]
    j += ["//OBJ2     DD DSN=&&OBJ2,DISP=(NEW,PASS),",
          f"//            {pds_fb},",
          "//            UNIT=SYSDA,SPACE=(TRK,(15,5,10))"]
    for n in ("LIBA", "LIBB", "OUT"):
        j += [f"//{n:<8} DD DSN=&&{n},DISP=(NEW,PASS),{pds_u},",
              "//            UNIT=SYSDA,SPACE=(TRK,(15,5,10))"]
    for obj in SRC:
        j += asm_step(obj, "OBJ2" if obj == "MC2" else "OBJ")
    j += lib_step("LXA", "XA", "LIBA", "XX")
    j += lib_step("LXB", "XB", "LIBB", "XX")
    j += lib_step("LYM", "YM", "LIBA", "YMEM")
    j += lib_step("LZM", "ZM", "LIBA", "ZMEM", alias="ZLD")
    j += lib_step("LWW", "WW", "LIBA", "WW")
    j += lib_step("LRR", "RR", "LIBA", "RR")
    j += link_step("TA1", ["MA"], ["LIBA", "LIBB"])
    j += link_step("TA2", ["MA"], ["LIBB", "LIBA"])
    j += link_step("TB", ["MB"], ["LIBA"])
    j += link_step("TB2", ["MZ"], ["LIBA"])
    j += link_step("TC", ["MC", "MC2"], ["LIBA"])
    j += link_step("TC2", ["MD"], ["LIBA"])
    j += lib_step("BD", "TT", "LIBA", "TT", alias="XX")
    j += link_step("TD", ["MA"], ["LIBA"])
    j.append("//")
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

    sys.path.insert(0, "/Users/mike/repos/mvs/mvs38src/tools")
    from creds import pair                          # noqa: E402
    user, pw = pair("MVSCE-LAB") if args.submit else ("IBMUSER", None)

    jcl = build_jcl()
    if not gate(jcl):
        return 1
    if not args.submit:
        print("\n".join(jcl))
        return 0

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
    from mbt.mvsmf import MvsMFClient               # noqa: E402
    client = MvsMFClient(host=HOST, port=PORT, user=user, password=pw)
    res = client.submit_jcl("\n".join(jcl) + "\n", wait=True, timeout=600)
    with open(args.out, "w") as fp:
        fp.write(res.spool)
    print(f"=== {res.jobname} {res.jobid} status={res.status} -> {args.out}")
    for ln in res.spool.splitlines():
        if re.search(r"IEW\d|IEF142I|IEF472I|ABEND|COMPLETION CODE", ln):
            print("  " + ln.rstrip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
