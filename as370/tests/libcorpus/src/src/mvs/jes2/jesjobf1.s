         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesjobf1 prologue
JESJOBF1 PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesjobf1 code
         L     8,0(11)
         LTR   8,8
         BE    @@L3
         L     3,0(8)
         LTR   3,3
         BE    @@L3
         L     2,48(3)
         LTR   2,2
         BE    @@L5
         LR    7,3
         A     7,=F'48'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
         SLR   4,4
@@L13    EQU   *
         CLR   4,6
         BNL   @@L12
         L     2,48(3)
         LR    5,4
         SLL   5,2
         L     2,0(5,2)
         LTR   2,2
         BE    @@L8
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,48(3)
         SLR   9,9
         ST    9,0(5,2)
@@L8     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L13
@@L12    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,8),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function jesjobf1 epilogue
         PDPEPIL
* Function jesjobf1 literal pool
         DS    0F
         LTORG
* Function jesjobf1 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
