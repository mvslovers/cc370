         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strcpy prologue
STRCPY   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strcpy code
         L     15,0(11)
         L     4,4(11)
         LR    3,15
@@L2     EQU   *
         IC    2,0(4)
         A     4,=F'1'
         STC   2,0(3)
         A     3,=F'1'
         CLM   2,1,=XL1'00'
         BNE   @@L2
* Function strcpy epilogue
         PDPEPIL
* Function strcpy literal pool
         DS    0F
         LTORG
* Function strcpy page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
