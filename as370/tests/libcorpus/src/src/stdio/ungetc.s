         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ungetc prologue
UNGETC   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ungetc code
         L     3,0(11)
         L     4,4(11)
         SLR   5,5
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         LA    5,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
         L     2,20(4)
         L     6,=F'-1'
         CLR   2,6
         BNE   @@L4
         CLR   3,6
         BNE   @@L3
@@L4     EQU   *
         L     12,0(,10)
         L     3,=F'-1'
         B     @@L5
@@L3     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=XL4'000000FF'
         ST    2,20(4)
@@L5     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L6
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         LR    15,3
* Function ungetc epilogue
         PDPEPIL
* Function ungetc literal pool
         DS    0F
         LTORG
* Function ungetc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
