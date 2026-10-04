         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mtxheld prologue
MTXHELD  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxheld code
         L     4,0(11)
         SLR   2,2
         L     3,540(2)
         LR    15,2
         L     2,4(4)
         LTR   2,2
         BE    @@L2
         L     2,0(4)
         CLR   2,3
         BNE   @@L2
         LA    15,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
* Function mtxheld epilogue
         PDPEPIL
* Function mtxheld literal pool
         DS    0F
         LTORG
* Function mtxheld page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
