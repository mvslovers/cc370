* cc370#563: ORG whose operand names a symbol not defined yet --
* never (IFO188) or further down (IFO231). Every case has its own
* names. Two rules, and what each predicts:
*  H1 the term is 0      the counter goes to 0 (or to 0+4)
*  H2 the ORG is ignored the counter stays where it was
*
*  C1 CSECT, counter x'08', ORG NEVERC    H1: CAFT = 0 (overlays
*                                          F'1'), H2: CAFT = 8
*  C2 CSECT, counter x'0D', ORG NEVERX+4  H1: XAFT = 4, H2: x'0D'
*  F1 CSECT, counter x'0E', ORG FWDL      H1: FAFT = 0, H2: x'0E'
*     (FWDL is a label further down)      IFO231
*  D1 DSECT, counter x'10', ORG NEVERD    H1: DAFT = 0, H2: x'10'
*  C1, C2, D1: IFO188 on the never-defined name
* A bare ORG after each CSECT case returns to the high-water mark,
* so the constants reporting the answer land where both agree.
T        CSECT
         DC    F'1'
         DC    F'2'
         ORG   NEVERC
CAFT     DC    X'AA'
         ORG
         DC    X'BBBBBBBB'
         ORG   NEVERX+4
XAFT     DC    X'CC'
         ORG
         ORG   FWDL
FAFT     DC    X'EE'
         ORG
         DS    0F
         DC    AL2(CAFT-T)
         DC    AL2(XAFT-T)
         DC    AL2(FAFT-T)
         DC    AL2(DAFT-D)
         DC    AL2(DEND-D)
FWDL     DC    X'FF'
D        DSECT
         DS    XL16
         ORG   NEVERD
DAFT     DS    F
DEND     DS    0F
         END
