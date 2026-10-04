         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'ABCDEFGHIJKLMNOPQRSTUVWXYZ@#$'
         DC    X'0'
@V2      EQU   *
         DC    C'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$'
         DC    X'0'
@@LC0    EQU   *
         DC    C' DELETE %s'
         DC    X'0'
         DS    0F
* X-func remove prologue
REMOVE   PDPPRLG CINDEX=0,FRAME=480,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function remove code
         L     9,0(11)
         ST    9,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         CLI   0(9),97
         BE    @@L2
         LTR   15,15
         BE    @@L2
         LR    6,15
         A     6,=F'1'
         ST    6,88(13)
         MVC   92(4,13),=F'93'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         IC    2,1(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L2
         LR    5,15
         SR    5,3
         LA    2,1(0,0)
         CR    5,2
         BNH   @@L2
         LA    2,9(0,0)
         CR    5,2
         BH    @@L2
         CR    3,9
         BE    @@L2
         LR    7,3
         SR    7,9
         LA    2,44(0,0)
         CR    7,2
         BH    @@L2
         SLR   4,4
         LR    2,5
         BCTR  2,0
         CR    4,2
         BNL   @@L25
         LA    8,464(,13)
@@L10    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(8)
         L     3,=A(@V1)
         LTR   4,4
         BE    @@L9
         L     3,=A(@V2)
@@L9     EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(8)
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         A     4,=F'1'
         A     6,=F'1'
         A     8,=F'1'
         LR    2,5
         BCTR  2,0
         CR    4,2
         BL    @@L10
@@L25    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,464(4,13)
         SLR   4,4
         CR    4,7
         BNL   @@L21
         LA    15,416(,13)
@@L15    EQU   *
         SLR   2,2
         IC    2,0(4,9)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(15)
         A     4,=F'1'
         A     15,=F'1'
         CR    4,7
         BL    @@L15
@@L21    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,416(4,13)
         LA    2,416(,13)
         ST    2,88(13)
         LA    2,464(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@DELMEM)
         BALR  14,15
         LR    2,15
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LA    5,104(,13)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LR    4,5
         IC    2,0(5)
@@L26    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L23
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
         A     4,=F'1'
         IC    2,0(4)
         B     @@L26
@@L23    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=V(IDCAMS)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(IDCAMS)
         BALR  14,15
         LR    2,15
         MVC   88(4,13),=V(IDCAMS)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function remove epilogue
         PDPEPIL
* Function remove literal pool
         DS    0F
         LTORG
* Function remove page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
