         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __sofind prologue
@@SOFIND PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __sofind code
         L     9,0(11)
         L     8,4(11)
         SLR   7,7
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L3
         LR    6,15
         A     6,=F'28'
         ST    6,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,7
         CLR   7,15
         BNL   @@L5
@@L10    EQU   *
         L     3,28(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L6
         L     2,8(3)
         CLR   2,9
         BNE   @@L6
         LTR   8,8
         BE    @@L9
         ST    3,0(8)
@@L9     EQU   *
         L     12,0(,10)
         LR    7,5
         A     7,=F'1'
         B     @@L5
@@L6     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         CLR   5,15
         BL    @@L10
@@L5     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function __sofind epilogue
         PDPEPIL
* Function __sofind literal pool
         DS    0F
         LTORG
* Function __sofind page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
