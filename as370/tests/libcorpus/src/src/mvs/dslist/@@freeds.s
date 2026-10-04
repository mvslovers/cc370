         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __freeds prologue
@@FREEDS PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __freeds code
         L     2,0(11)
         LTR   2,2
         BE    @@L1
         LR    3,2
         L     2,0(2)
         LTR   2,2
         BE    @@L1
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L3
         L     7,0(3)
         SLR   9,9
@@L18    EQU   *
         CLR   9,6
         BNL   @@L3
         LR    8,9
         SLL   8,2
         L     2,0(8,7)
         LTR   2,2
         BE    @@L6
         L     5,100(2)
         LTR   5,5
         BE    @@L8
         LR    4,9
         A     4,=F'1'
         CLR   4,6
         BNL   @@L17
         LR    3,4
         SLL   3,2
         AR    3,7
@@L13    EQU   *
         L     15,0(3)
         LTR   15,15
         BE    @@L11
         L     2,100(15)
         CLR   2,5
         BNE   @@L11
         MVC   100(4,15),=F'0'
@@L11    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         A     3,=F'4'
         CLR   4,6
         BL    @@L13
@@L17    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         L     2,0(8,7)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   3,3
         ST    3,0(8,7)
@@L6     EQU   *
         L     12,0(,10)
         A     9,=F'1'
         B     @@L18
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         L     2,0(11)
         MVC   0(4,2),=F'0'
@@L1     EQU   *
         L     12,0(,10)
* Function __freeds epilogue
         PDPEPIL
* Function __freeds literal pool
         DS    0F
         LTORG
* Function __freeds page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
