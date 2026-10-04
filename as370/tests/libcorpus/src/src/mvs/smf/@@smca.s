         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __smca prologue
@@SMCA   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __smca code
         SLR   2,2
         L     2,16(2)
         L     15,196(2)
* Function __smca epilogue
         PDPEPIL
* Function __smca literal pool
         DS    0F
         LTORG
* Function __smca page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
