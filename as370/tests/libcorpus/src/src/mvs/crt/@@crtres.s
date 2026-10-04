         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __CRTRES prologue
@@CRTRES PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __CRTRES code
         L     8,=F'-1'
         SLR   2,2
         L     7,540(2)
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L3
         ST    15,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         LR    6,5
         A     6,=F'12'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,2
@@L12    EQU   *
         CLR   4,15
         BNL   @@L6
         L     3,12(5)
         LR    2,4
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L7
         L     2,8(3)
         CLR   2,7
         BNE   @@L7
         ST    6,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   8,8
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L12
@@L6     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,8
* Function __CRTRES epilogue
         PDPEPIL
* Function __CRTRES literal pool
         DS    0F
         LTORG
* Function __CRTRES page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
