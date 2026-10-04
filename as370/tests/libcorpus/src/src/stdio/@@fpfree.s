         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fpfree prologue
@@FPFREE PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpfree code
         L     2,0(11)
         SLR   15,15
         ST    15,120(13)
         LA    6,96(,13)
         LA    7,20(0,0)
         LR    4,15
         LR    5,15
         MVCL  6,4
         LA    3,120(,13)
         ST    3,88(13)
         A     2,=F'43'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDDN)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNE   @@L3
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXUNAL)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNE   @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         LR    2,15
         BCTR  2,0
         L     4,120(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),2
         STC   5,98(13)
         MVC   104(4,13),120(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    5,15
@@L3     EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L6
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         LR    15,5
* Function __fpfree epilogue
         PDPEPIL
* Function __fpfree literal pool
         DS    0F
         LTORG
* Function __fpfree page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
