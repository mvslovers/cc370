         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __freepd prologue
@@FREEPD PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __freepd code
         L     6,0(11)
         LTR   6,6
         BE    @@L1
         L     2,0(6)
         LTR   2,2
         BE    @@L1
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         L     7,0(6)
         SLR   4,4
@@L10    EQU   *
         CLR   4,3
         BNL   @@L3
         LR    5,4
         SLL   5,2
         L     2,0(5,7)
         LTR   2,2
         BE    @@L6
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   2,2
         ST    2,0(5,7)
@@L6     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L10
@@L3     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         MVC   0(4,6),=F'0'
@@L1     EQU   *
         L     12,0(,10)
* Function __freepd epilogue
         PDPEPIL
* Function __freepd literal pool
         DS    0F
         LTORG
* Function __freepd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
