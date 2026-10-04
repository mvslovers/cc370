         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func system prologue
SYSTEM   PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function system code
         L     8,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    9,15
         ST    8,88(13)
         MVC   92(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BNE   @@L2
         ST    8,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    7,15
@@L2     EQU   *
         L     12,0(,10)
         LR    6,7
         SR    6,8
         L     15,=F'-1'
         LA    2,8(0,0)
         CLR   6,2
         BH    @@L1
         LA    4,112(,13)
         LR    5,6
         LR    2,8
         LR    3,6
         MVCL  4,2
         SLR   2,2
         STC   2,112(13,6)
         SLR   5,5
         CLR   5,6
         BNL   @@L12
         LA    4,112(,13)
@@L7     EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
         A     5,=F'1'
         A     4,=F'1'
         CLR   5,6
         BL    @@L7
@@L12    EQU   *
         L     12,0(,10)
         IC    2,0(7)
         CLM   2,1,=XL1'00'
         BE    @@L8
         A     7,=F'1'
@@L8     EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         IC    2,10(9)
         N     2,=F'64'
         BCTR  2,0
         SRL   2,31
         LA    3,2(0,0)
         SR    3,2
         ST    3,88(13)
         ST    6,92(13)
         LA    2,112(,13)
         ST    2,96(13)
         ST    15,100(13)
         ST    7,104(13)
         LA    1,88(,13)
         L     15,=V(@@SYSTEM)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function system epilogue
         PDPEPIL
* Function system literal pool
         DS    0F
         LTORG
* Function system page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
