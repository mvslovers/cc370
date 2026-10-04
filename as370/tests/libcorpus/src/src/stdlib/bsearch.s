         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func bsearch prologue
BSEARCH  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function bsearch code
         SLR   6,6
         SLR   7,7
         L     5,4(11)
         L     2,8(11)
         L     8,12(11)
         L     9,16(11)
@@L12    EQU   *
         LTR   2,2
         BE    @@L10
         LR    4,2
         SRL   4,1
         LR    7,4
         MR    6,8
         LR    3,5
         AR    3,7
         ST    3,88(13)
         MVC   92(4,13),0(11)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         LR    15,3
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNL   @@L6
         SR    2,4
         BCTR  2,0
         LR    5,3
         AR    5,8
         B     @@L12
@@L6     EQU   *
         L     12,0(,10)
         LR    2,4
         B     @@L12
@@L10    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function bsearch epilogue
         PDPEPIL
* Function bsearch literal pool
         DS    0F
         LTORG
* Function bsearch page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
