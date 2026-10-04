         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func labs prologue
LABS     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function labs code
         L     2,0(11)
         LPR   15,2
* Function labs epilogue
         PDPEPIL
* Function labs literal pool
         DS    0F
         LTORG
* Function labs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
