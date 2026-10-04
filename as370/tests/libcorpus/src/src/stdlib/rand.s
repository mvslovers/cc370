         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rand prologue
RAND     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rand code
         SLR   2,2
         SLR   3,3
         SLR   4,4
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         L     3,=F'1103515245'
         L     4,20(15)
         MR    2,4
         LR    2,3
         A     2,=F'12345'
         ST    2,20(15)
         LR    4,2
         SRL   4,16
         N     4,=F'36863'
@@L2     EQU   *
         L     12,0(,10)
         LR    15,4
* Function rand epilogue
         PDPEPIL
* Function rand literal pool
         DS    0F
         LTORG
* Function rand page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
