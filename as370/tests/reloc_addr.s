RELOC21P CSECT
         PRINT GEN
*  1 plain CSECT symbol, no USING -> :363 -> IFO209
         L     1,LABX
*  2 literal, no USING -> IFO209
         L     1,=F'7'
         USING RELOC21P,12
*  3 addressable compound, same section r12 -> resolves
         L     1,LABX+4-4
*  4 addressable literal r12 -> resolves
         L     1,=F'9'
*  5 plain DSECT symbol, r12 in range, no MYDS USING -> :361 -> IFO209
         L     1,FLDX
*  6 compound DSECT expr, r12 in range, no MYDS USING -> :361 -> IFO209
         L     1,FLDX+8-8
         USING MYDS,13
*  7 compound DSECT expr with r13 -> resolves  (case-b alarm)
         L     1,FLDX+8-8
*  8 plain DSECT symbol with r13 -> resolves
         L     1,FLDX
         DROP  13
         DROP  12
LABX     DS    F
         LTORG
MYDS     DSECT
         DS    XL40
FLDX     DS    F
         END
