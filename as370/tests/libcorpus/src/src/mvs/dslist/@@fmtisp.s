         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'%06X'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%02u.%02u'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%02u-%02u-%02u'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%02u-%02u-%02u %02X:%02X:%02X'
         DC    X'0'
@@LC4    EQU   *
         DC    C'%u'
         DC    X'0'
         DS    0F
* X-func __fmtisp prologue
@@FMTISP PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fmtisp code
         SLR   6,6
         SLR   7,7
         LR    8,6
         LR    9,7
         L     4,4(11)
         L     15,=F'-1'
         L     2,0(11)
         LTR   2,2
         BE    @@L5
         LR    5,2
         A     5,=F'12'
         BE    @@L5
         LTR   4,4
         BE    @@L5
         SLR   3,3
         LA    2,76(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         L     15,0(11)
         CLI   0(15),64
         BNH   @@L9
         LR    2,15
@@L11    EQU   *
         IC    15,0(2)
         STC   15,0(3,4)
         A     3,=F'1'
         A     2,=F'1'
         LA    15,7(0,0)
         CR    3,15
         BH    @@L9
         CLI   0(2),64
         BH    @@L11
@@L9     EQU   *
         L     12,0(,10)
         A     4,=F'9'
         ST    4,88(13)
         A     4,=F'-9'
         MVC   92(4,13),=A(@@LC0)
         L     3,0(11)
         L     2,8(3)
         SRL   2,8
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         IC    15,11(3)
         N     15,=F'31'
         AR    15,15
         BE    @@L5
         A     4,=F'16'
         ST    4,88(13)
         A     4,=F'-16'
         MVC   92(4,13),=A(@@LC1)
         SLR   2,2
         IC    2,0(5)
         ST    2,96(13)
         SLR   2,2
         IC    2,1(5)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         SLR   2,2
         IC    2,4(5)
         ST    2,88(13)
         A     5,=F'5'
         ST    5,92(13)
         A     5,=F'-5'
         LA    3,120(,13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BNE   @@L13
         A     4,=F'22'
         ST    4,88(13)
         A     4,=F'-22'
         MVC   92(4,13),=A(@@LC2)
         L     6,140(13)
         SRDA  6,32
         LA    15,100(0,0)
         DR    6,15
         ST    6,96(13)
         L     2,136(13)
         A     2,=F'1'
         ST    2,100(13)
         MVC   104(4,13),132(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L13    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,8(5)
         ST    2,88(13)
         A     5,=F'9'
         ST    5,92(13)
         A     5,=F'-9'
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BNE   @@L14
         A     4,=F'31'
         ST    4,88(13)
         A     4,=F'-31'
         MVC   92(4,13),=A(@@LC3)
         L     8,140(13)
         SRDA  8,32
         LA    2,100(0,0)
         DR    8,2
         ST    8,96(13)
         L     2,136(13)
         A     2,=F'1'
         ST    2,100(13)
         MVC   104(4,13),132(13)
         SLR   2,2
         IC    2,12(5)
         ST    2,108(13)
         SLR   2,2
         IC    2,13(5)
         ST    2,112(13)
         SLR   2,2
         IC    2,3(5)
         ST    2,116(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         A     4,=F'49'
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC4)
         LH    2,16(5)
         N     2,=XL4'0000FFFF'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     4,=F'6'
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC4)
         LH    2,14(5)
         N     2,=XL4'0000FFFF'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     4,=F'6'
         ST    4,88(13)
         A     4,=F'-61'
         MVC   92(4,13),=A(@@LC4)
         LH    2,18(5)
         N     2,=XL4'0000FFFF'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         SLR   3,3
         CLI   20(5),64
         BNH   @@L16
         LR    2,5
         A     2,=F'20'
         A     4,=F'67'
@@L18    EQU   *
         MVC   0(1,4),0(2)
         A     3,=F'1'
         A     4,=F'1'
         A     2,=F'1'
         LA    5,7(0,0)
         CR    3,5
         BH    @@L16
         CLI   0(2),64
         BH    @@L18
@@L16    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L5     EQU   *
         L     12,0(,10)
* Function __fmtisp epilogue
         PDPEPIL
* Function __fmtisp literal pool
         DS    0F
         LTORG
* Function __fmtisp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function cvtdate,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function cvtdate code
         L     5,4(11)
         L     4,8(11)
         SLR   6,6
         LA    2,36(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,6            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         IC    2,0(5)
         N     2,=F'240'
         SRA   2,4
         LR    3,2
         SLL   3,3
         AR    3,2
         AR    3,2
         ST    3,20(4)
         IC    15,0(5)
         N     15,=F'15'
         AR    15,3
         ST    15,20(4)
         L     2,0(11)
         LTR   2,2
         BE    @@L24
         A     15,=F'100'
         ST    15,20(4)
@@L24    EQU   *
         L     12,0(,10)
         IC    2,1(5)
         N     2,=F'240'
         SRA   2,4
         LR    3,2
         SLL   3,3
         AR    3,2
         AR    3,2
         ST    3,12(4)
         IC    2,1(5)
         N     2,=F'15'
         AR    2,3
         LR    3,2
         SLL   3,3
         AR    3,2
         AR    3,2
         ST    3,12(4)
         IC    2,2(5)
         N     2,=F'240'
         SRA   2,4
         AR    3,2
         ST    3,12(4)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         LR    15,6
* Function cvtdate epilogue
         PDPEPIL
* Function cvtdate literal pool
         DS    0F
         LTORG
* Function cvtdate page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
