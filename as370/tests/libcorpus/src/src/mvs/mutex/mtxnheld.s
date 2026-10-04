         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mtxnheld prologue
MTXNHELD PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxnheld code
         L     4,0(11)
         SLR   2,2
         L     3,540(2)
         LR    15,2
         L     2,4(4)
         LTR   2,2
         BE    @@L3
         L     2,0(4)
         CLR   2,3
         BE    @@L2
@@L3     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
* Function mtxnheld epilogue
         PDPEPIL
* Function mtxnheld literal pool
         DS    0F
         LTORG
* Function mtxnheld page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
