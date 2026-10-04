         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fpterm prologue
@@FPTERM PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpterm code
         L     5,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    6,15
         SLR   7,7
         L     2,28(5)
         LTR   2,2
         BE    @@L2
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         ST    7,28(5)
         ST    7,32(5)
         ST    7,36(5)
@@L2     EQU   *
         L     12,0(,10)
         LH    2,40(5)
         CH    2,=H'0'
         BNL   @@L3
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPFREE)
         BALR  14,15
         LR    7,15
@@L3     EQU   *
         L     12,0(,10)
         LR    4,6
         A     4,=F'24'
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
@@L10    EQU   *
         LTR   15,15
         BE    @@L5
         BCTR  15,0
         L     2,24(6)
         LR    3,15
         SLL   3,2
         L     2,0(3,2)
         CLR   2,5
         BNE   @@L10
         ST    4,88(13)
         A     15,=F'1'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         A     6,=F'24'
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,4(11)
         LTR   2,2
         BE    @@L8
         ST    5,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LR    15,7
* Function __fpterm epilogue
         PDPEPIL
* Function __fpterm literal pool
         DS    0F
         LTORG
* Function __fpterm page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
