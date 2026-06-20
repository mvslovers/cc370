#!/usr/bin/env python3
"""2x2 content-vs-placement discriminator for the multi-text fetch truncation.

Uses the existing KEPT datasets from the dir-dump oracle on WORK01:
  IBMUSER.NOPTDD.RCV   -- ld370 module (RECV370-reloaded)   -> abends S0C1
  IBMUSER.NOPTDD.IEWL  -- IEWL-linked SAME nopt.o           -> runs RC=0

IEBCOPY-copies each into a fresh load library, then runs all four members:
  rcv  (ld370 original)   expect S0C1   (known)
  iewl (IEWL original)    expect RC=0   (known)
  rcvc (ld370 copied)     expect S0C1   (known from recopy)
  iewlc(IEWL copied)      <== THE NEW DATUM

If iewlc runs RC=0 while rcvc abends -- both through the SAME IEBCOPY COPY --
the difference is the INPUT MEMBER CONTENT (IDR-82 / off33), not the physical
placement.  If iewlc also abends, IEBCOPY COPY itself breaks load modules and
the fault is in the transport/placement path, independent of ld370's member.
"""
import sys

sys.path.insert(0, "/Users/mike/repos/mvs/mbt/scripts")
import os
os.chdir("/Users/mike/repos/mvs/crent370")
from mbt.config import MbtConfig
from mbt.jcl import jobcard
from mbt.mvsmf import MvsMFClient

cfg = MbtConfig()
hlq = cfg.get("mvs.hlq")
rcv = f"{hlq}.NOPTDD.RCV"
iewl = f"{hlq}.NOPTDD.IEWL"
rcvc = f"{hlq}.NOPTDD.RCVC"
iewlc = f"{hlq}.NOPTDD.IEWLC"

client = MvsMFClient(host=cfg.mvs_host, port=cfg.mvs_port,
                     user=cfg.mvs_user, password=cfg.mvs_pass)

for dsn in (rcvc, iewlc):
    try:
        client.delete_dataset(dsn)
    except Exception:
        pass

jc = jobcard("NOPT2X2", cfg.jes_jobclass, cfg.jes_msgclass, "2X2 DISCRIM")
jcl = f"""{jc}
//CPYRCV   EXEC PGM=IEBCOPY
//SYSPRINT DD SYSOUT=*
//IN       DD DSN={rcv},DISP=SHR
//OUT      DD DSN={rcvc},DISP=(NEW,CATLG),UNIT=SYSDA,
//            SPACE=(CYL,(2,1,5)),DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT3   DD UNIT=VIO,SPACE=(CYL,(2,1))
//SYSUT4   DD UNIT=VIO,SPACE=(CYL,(2,1))
//SYSIN    DD *
  COPY OUTDD=OUT,INDD=IN
/*
//CPYIEWL  EXEC PGM=IEBCOPY
//SYSPRINT DD SYSOUT=*
//IN       DD DSN={iewl},DISP=SHR
//OUT      DD DSN={iewlc},DISP=(NEW,CATLG),UNIT=SYSDA,
//            SPACE=(CYL,(2,1,5)),DCB=(RECFM=U,BLKSIZE=19069)
//SYSUT3   DD UNIT=VIO,SPACE=(CYL,(2,1))
//SYSUT4   DD UNIT=VIO,SPACE=(CYL,(2,1))
//SYSIN    DD *
  COPY OUTDD=OUT,INDD=IN
/*
//RUNRCV   EXEC PGM=NOPT,COND=EVEN
//STEPLIB  DD DSN={rcv},DISP=SHR
//SYSPRINT DD SYSOUT=*
//RUNIEWL  EXEC PGM=NOPT,COND=EVEN
//STEPLIB  DD DSN={iewl},DISP=SHR
//SYSPRINT DD SYSOUT=*
//RUNRCVC  EXEC PGM=NOPT,COND=EVEN
//STEPLIB  DD DSN={rcvc},DISP=SHR
//SYSPRINT DD SYSOUT=*
//RUNIEWLC EXEC PGM=NOPT,COND=EVEN
//STEPLIB  DD DSN={iewlc},DISP=SHR
//SYSPRINT DD SYSOUT=*
//
"""

res = client.submit_jcl(jcl, wait=True, timeout=220)
spool = res.spool
out = "/tmp/dirdump/r2x2.txt"
open(out, "w").write(spool)
print(f"=== {res.jobname} {res.jobid} status={res.status} -> {out} ===")
import re
for ln in spool.splitlines():
    if re.search(r"IEF142I|IEF450I|IEF472I|COND CODE|SYSTEM=0C1|ABEND|IEB154I|IEB167I|RUN(RCV|IEWL|RCVC|IEWLC)", ln):
        print("  " + ln.rstrip())
