         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ferror prologue
FERROR   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ferror code
         L     2,0(11)
         IC    15,41(2)
         SRL   15,1
         N     15,=F'1'
* Function ferror epilogue
         PDPEPIL
* Function ferror literal pool
         DS    0F
         LTORG
* Function ferror page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
