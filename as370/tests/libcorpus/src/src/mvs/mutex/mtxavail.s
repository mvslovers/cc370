         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mtxavail prologue
MTXAVAIL PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxavail code
         L     3,0(11)
         SLR   15,15
         L     2,4(3)
         LTR   2,2
         BNE   @@L2
         L     2,0(3)
         LTR   2,2
         BNE   @@L2
         LA    15,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
* Function mtxavail epilogue
         PDPEPIL
* Function mtxavail literal pool
         DS    0F
         LTORG
* Function mtxavail page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
