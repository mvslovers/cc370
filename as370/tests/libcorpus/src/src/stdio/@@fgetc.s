         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'/*'
         DC    X'0'
@@LC1    EQU   *
         DC    C'//'
         DC    X'0'
@@LC2    EQU   *
         DC    C'<eof>'
         DC    X'0'
@@LC3    EQU   *
         DC    C'<EOF>'
         DC    X'0'
         DS    0F
* X-func __fgetc prologue
@@FGETC  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fgetc code
         L     7,0(11)
         L     4,8(7)
         L     5,=F'-1'
         LH    3,40(7)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'9'
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BNE   @@L33
         N     3,=F'16'
         LTR   3,3
         BE    @@L5
         ST    7,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
@@L5     EQU   *
         L     12,0(,10)
         LH    2,40(7)
         N     2,=F'513'
         LTR   2,2
         BNE   @@L3
         L     2,20(7)
         L     3,=F'-1'
         CLR   2,3
         BE    @@L8
         LR    5,2
         ST    3,20(7)
         B     @@L3
@@L8     EQU   *
         L     12,0(,10)
         L     2,32(7)
         CL    2,36(7)
         BL    @@L10
         CLI   17(4),79
         BNE   @@L11
         MVC   88(4,13),12(7)
         LH    2,16(7)
         N     2,=XL4'0000FFFF'
         BCTR  2,0
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LR    3,15
         ST    15,104(13)
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
         L     2,=A(@@LC0)
         CLC   0(3,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
         L     2,=A(@@LC1)
         CLC   0(3,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
         L     2,=A(@@LC2)
         CLC   0(6,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
         L     2,=A(@@LC3)
         CLC   0(6,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L16
         B     @@L3
@@L11    EQU   *
         L     12,0(,10)
         IC    2,191(7)
         N     2,=F'2'
         LTR   2,2
         BE    @@L17
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
@@L17    EQU   *
         L     12,0(,10)
         MVC   88(4,13),8(7)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AREAD)
         BALR  14,15
         LTR   15,15
         BE    @@L20
         LH    2,40(7)
         BNH   @@L21
         O     2,=F'2'
         STH   2,40(7)
@@L33    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
         B     @@L3
@@L21    EQU   *
         L     12,0(,10)
         O     2,=F'1'
         STH   2,40(7)
         B     @@L3
@@L20    EQU   *
         L     12,0(,10)
         IC    2,42(7)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L24
         BH    @@L28
         LA    3,64(0,0)
         CLR   2,3
         BE    @@L25
         B     @@L27
@@L28    EQU   *
         L     12,0(,10)
         LA    3,192(0,0)
         CLR   2,3
         BE    @@L26
         B     @@L27
@@L24    EQU   *
         L     12,0(,10)
         LH    6,16(7)
         N     6,=XL4'0000FFFF'
         B     @@L16
@@L25    EQU   *
         L     12,0(,10)
         L     2,104(13)
         SLR   6,6
         IC    6,0(2)
         SLL   6,8
         SLR   3,3
         IC    3,1(2)
         OR    6,3
         A     2,=F'4'
         ST    2,104(13)
         A     6,=F'-4'
         B     @@L16
@@L26    EQU   *
         L     12,0(,10)
         L     6,108(13)
         B     @@L16
@@L27    EQU   *
         L     12,0(,10)
         OC    40(2,7),=H'1'
         B     @@L3
@@L16    EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L29
         LH    2,40(7)
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L30
         MVC   88(4,13),104(13)
         ST    2,92(13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(MEMCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L30
         LR    6,15
         S     6,104(13)
@@L30    EQU   *
         L     12,0(,10)
         L     4,28(7)
         LR    5,6
         L     2,104(13)
         LR    3,6
         MVCL  4,2
@@L29    EQU   *
         L     12,0(,10)
         MVC   32(4,7),28(7)
         L     15,28(7)
         AR    15,6
         ST    15,36(7)
         LH    2,40(7)
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L10
         MVI   0(15),21
         A     15,=F'1'
         ST    15,36(7)
@@L10    EQU   *
         L     12,0(,10)
         LR    2,7
         A     2,=F'32'
         L     3,0(2)
         SLR   5,5
         IC    5,0(3)
         A     3,=F'1'
         ST    3,0(2)
         L     2,24(7)
         A     2,=F'1'
         ST    2,24(7)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function __fgetc epilogue
         PDPEPIL
* Function __fgetc literal pool
         DS    0F
         LTORG
* Function __fgetc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function tso_getline,F2 prologue
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
* Function tso_getline code
         L     4,0(11)
         L     15,4(11)
         LTR   4,4
         BE    @@L36
         LTR   15,15
         BE    @@L36
         LR    2,4
         N     2,=F'16777215'
         O     2,=F'-2147483648'
         LR    0,15                buffer length
         LR    1,2                flags and buffer address
         TGET  (1),(0),R
         AR    15,4
         BCTR  15,0
         MVI   0(15),0
         SLR   15,15
         SLR   2,2
         IC    2,0(4)
         L     5,=V(@@ISBUF)
         L     3,0(5)
@@L49    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L47
         A     15,=F'1'
         SLR   2,2
         IC    2,0(15,4)
         B     @@L49
@@L47    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         AR    15,4
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L36
         AR    15,4
@@L45    EQU   *
         BCTR  15,0
         SLR   2,2
         IC    2,0(15)
         L     3,0(5)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L36
         MVI   0(15),0
         CLR   15,4
         BNE   @@L45
@@L36    EQU   *
         L     12,0(,10)
         LR    15,4
* Function tso_getline epilogue
         PDPEPIL
* Function tso_getline literal pool
         DS    0F
         LTORG
* Function tso_getline page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
