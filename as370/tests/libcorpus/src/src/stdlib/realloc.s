         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func realloc prologue
REALLOC  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function realloc code
         L     8,0(11)
         L     6,4(11)
         LTR   6,6
         BNE   @@L2
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LR    15,6
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(MALLOC)
         BALR  14,15
         LR    7,15
         LTR   7,7
         BE    @@L1
         LTR   8,8
         BE    @@L4
         L     2,=F'-4'
         L     2,0(2,8)
         CLR   2,6
         BNL   @@L5
         LR    6,2
@@L5     EQU   *
         L     12,0(,10)
         LR    4,7
         LR    5,6
         LR    2,8
         LR    3,6
         MVCL  4,2
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,7
@@L1     EQU   *
         L     12,0(,10)
* Function realloc epilogue
         PDPEPIL
* Function realloc literal pool
         DS    0F
         LTORG
* Function realloc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
