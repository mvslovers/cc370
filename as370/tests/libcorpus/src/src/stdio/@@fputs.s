         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fputs prologue
@@FPUTS  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fputs code
         L     3,0(11)
         L     5,4(11)
         LH    2,40(5)
         N     2,=F'512'
         L     4,=F'-1'
         LTR   2,2
         BNE   @@L3
         B     @@L2
@@L10    EQU   *
         LR    4,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LR    4,2
@@L11    EQU   *
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L3
         SLR   2,2
         IC    2,0(3)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPUTC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BE    @@L10
         A     4,=F'1'
         A     3,=F'1'
         B     @@L11
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __fputs epilogue
         PDPEPIL
* Function __fputs literal pool
         DS    0F
         LTORG
* Function __fputs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
