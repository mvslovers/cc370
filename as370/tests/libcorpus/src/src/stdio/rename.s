         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'ABCDEFGHIJKLMNOPQRSTUVWXYZ@#$'
         DC    X'0'
@V2      EQU   *
         DC    C'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$'
         DC    X'0'
         DS    0F
* Function split_member,F2 prologue
@@F2     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function split_member code
         L     9,0(11)
         LTR   9,9
         BE    @@L7
         CLI   0(9),97
         BE    @@L7
         ST    9,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L7
         CR    15,9
         BE    @@L7
         LR    8,15
         SR    8,9
         LA    2,44(0,0)
         CR    8,2
         BH    @@L7
         LR    7,15
         A     7,=F'1'
         ST    7,88(13)
         MVC   92(4,13),=F'93'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         IC    2,1(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L7
         LR    5,15
         SR    5,3
         LA    3,1(0,0)
         CR    5,3
         BNH   @@L7
         LA    2,9(0,0)
         CR    5,2
         BNH   @@L6
@@L7     EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         SLR   4,4
         LR    2,5
         BCTR  2,0
         CR    4,2
         BNL   @@L20
         L     6,8(11)
@@L14    EQU   *
         SLR   2,2
         IC    2,0(7)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(6)
         L     3,=A(@V1)
         LTR   4,4
         BE    @@L13
         L     3,=A(@V2)
@@L13    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(6)
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L1
         A     4,=F'1'
         A     7,=F'1'
         A     6,=F'1'
         LR    2,5
         BCTR  2,0
         CR    4,2
         BL    @@L14
@@L20    EQU   *
         L     12,0(,10)
         SLR   5,5
         L     3,8(11)
         STC   5,0(4,3)
         SLR   4,4
@@L24    EQU   *
         CR    4,8
         BNL   @@L22
         SLR   2,2
         IC    2,0(4,9)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         L     5,4(11)
         STC   2,0(4,5)
         A     4,=F'1'
         B     @@L24
@@L22    EQU   *
         L     12,0(,10)
         SLR   3,3
         L     2,4(11)
         STC   3,0(4,2)
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function split_member epilogue
         PDPEPIL
* Function split_member literal pool
         DS    0F
         LTORG
* Function split_member page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
@@LC0    EQU   *
         DC    C' ALTER %s NEWNAME(%s)'
         DC    X'0'
         DS    0F
* X-func rename prologue
RENAME   PDPPRLG CINDEX=1,FRAME=808,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function rename code
         L     6,0(11)
         L     7,4(11)
         ST    6,88(13)
         LA    2,680(,13)
         ST    2,92(13)
         LA    5,728(,13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L26
         ST    7,88(13)
         LA    3,744(,13)
         ST    3,92(13)
         LA    4,792(,13)
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L26
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LTR   15,15
         BNE   @@L26
         ST    2,88(13)
         ST    5,92(13)
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(@@RENMEM)
         BALR  14,15
         LR    2,15
         B     @@L25
@@L26    EQU   *
         L     12,0(,10)
         LA    4,104(,13)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    6,96(13)
         ST    7,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LR    15,4
         IC    2,0(4)
@@L32    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L31
         SLR   2,2
         IC    2,0(15)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(15)
         A     15,=F'1'
         IC    2,0(15)
         B     @@L32
@@L31    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=V(IDCAMS)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(IDCAMS)
         BALR  14,15
         LR    2,15
         MVC   88(4,13),=V(IDCAMS)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L25    EQU   *
         L     12,0(,10)
         LR    15,2
* Function rename epilogue
         PDPEPIL
* Function rename literal pool
         DS    0F
         LTORG
* Function rename page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
