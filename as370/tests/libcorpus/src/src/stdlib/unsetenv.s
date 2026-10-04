         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func unsetenv prologue
UNSETENV PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function unsetenv code
         L     9,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L1
         LR    6,15
         A     6,=F'32'
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   9,9
         BE    @@L3
         L     2,0(6)
         LTR   2,2
         BE    @@L3
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    8,15
         SLR   7,7
@@L12    EQU   *
         CLR   7,8
         BNL   @@L3
         L     2,32(5)
         LR    4,7
         SLL   4,2
         L     2,0(4,2)
         LTR   2,2
         BE    @@L6
         L     3,0(2)
         LTR   3,3
         BE    @@L13
         ST    3,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L6
@@L13    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,32(5)
         ST    3,0(4,2)
@@L6     EQU   *
         L     12,0(,10)
         A     7,=F'1'
         B     @@L12
@@L3     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function unsetenv epilogue
         PDPEPIL
* Function unsetenv literal pool
         DS    0F
         LTORG
* Function unsetenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
