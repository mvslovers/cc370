         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_dec'
* Program text area
         DS    0F
* X-func *@@64DEC prologue
@@64DEC  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64DEC code
         L     5,0(11)
         LTR   5,5
         BE    @@L1
         LA    15,3(0,0)
@@L7     EQU   *
         LR    2,15
         AR    2,15
         LH    4,0(2,5)
         LR    3,4
         BCTR  3,0
         STH   3,0(2,5)
         STH   4,80(,13)
         CLM   3,3,80(13)
         BNH   @@L1
         BCTR  15,0
         LTR   15,15
         BNL   @@L7
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64DEC epilogue
         PDPEPIL
* Function *@@64DEC literal pool
         DS    0F
         LTORG
* Function *@@64DEC page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
