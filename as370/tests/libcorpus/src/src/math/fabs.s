         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fabs prologue
FABS     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fabs code
         LD    0,0(11)
         LTDR  0,0
         BNL   @@L2
         LCDR  0,0
@@L2     EQU   *
         L     12,0(,10)
* Function fabs epilogue
         PDPEPIL
* Function fabs literal pool
         DS    0F
         LTORG
* Function fabs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
