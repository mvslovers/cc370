         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __nwtx99 prologue
@@NWTX99 PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __nwtx99 code
         SLR   6,6
         SLR   7,7
         L     3,4(11)
         L     4,8(11)
         L     8,12(11)
         LR    7,3
         MR    6,4
         MVC   88(4,13),=F'1'
         LR    2,7
         A     2,=F'8'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         L     2,0(11)
         STH   2,0(15)
         STH   3,2(15)
         STH   4,4(15)
         LTR   8,8
         BE    @@L2
         LR    4,15
         A     4,=F'6'
         LR    5,7
         LR    2,8
         LR    3,7
         MVCL  4,2
@@L2     EQU   *
         L     12,0(,10)
* Function __nwtx99 epilogue
         PDPEPIL
* Function __nwtx99 literal pool
         DS    0F
         LTORG
* Function __nwtx99 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
