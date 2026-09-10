* cc370 -- an S-type constant must take its base from an
* active USING, including a USING on an ABSOLUTE symbol.
* IECVESIO and IECVCINT write  CRCA EQU 0 / USING CRCA,R1 /
* DC X'8300',S(CRCAMCW)  and mean base 1, displacement 8.
*
* The control is inside the fixture: the two machine
* instructions resolve the same symbol under the same USING
* and must show the same base and displacement as the S-con.
SCONABS  CSECT
         USING CRCA,1
         NI    CRCAMCW,X'EF'
         L     2,CRCAMCW
         DC    S(CRCAMCW)
         DC    X'8300',S(CRCAMCW)
         DROP  1
CRCA     EQU   0
CRCAMCW  EQU   CRCA+8
         END
