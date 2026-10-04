         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'dd:%s(%s)'
         DC    X'0'
@@LC1    EQU   *
         DC    C'dd:%s'
         DC    X'0'
         DS    0F
* X-func __fseek prologue
@@FSEEK  PDPPRLG CINDEX=0,FRAME=1368,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fseek code
         L     4,0(11)
         L     8,4(11)
         L     7,8(11)
         LH    2,40(4)
         N     2,=F'-8'
         STH   2,40(4)
         LR    3,2
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BE    @@L2
         N     3,=F'4096'
         LTR   3,3
         BE    @@L2
         ST    4,88(13)
         ST    8,92(13)
         ST    7,96(13)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         L     5,24(4)
         LR    6,8
         LTR   7,7
         BE    @@L4
         LR    6,5
         AR    6,8
         LA    2,1(0,0)
         CLR   7,2
         BE    @@L4
         L     15,=F'-1'
         LA    2,2(0,0)
         CLR   7,2
         BNE   @@L1
         LH    2,40(4)
         N     2,=F'8192'
         LR    6,5
         AR    6,8
         LTR   2,2
         BE    @@L4
@@L10    EQU   *
         LA    2,368(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'1000'
         MVC   96(4,13),=F'1'
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(@@FREAD)
         BALR  14,15
         LA    7,1(0,0)
         CLR   15,7
         BE    @@L10
         B     @@L13
@@L4     EQU   *
         L     12,0(,10)
         LH    3,40(4)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BNE   @@L41
         CLR   6,5
         BE    @@L13
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'29'
         L     15,=F'-1'
         B     @@L1
@@L41    EQU   *
         L     12,0(,10)
         N     3,=F'512'
         LTR   3,3
         BE    @@L18
         CLR   6,5
         BNE   @@L17
         MVC   32(4,4),28(4)
         B     @@L13
@@L18    EQU   *
         L     12,0(,10)
         L     2,32(4)
         L     15,28(4)
         LR    3,2
         SR    3,15
         LR    7,5
         SR    7,3
         LR    3,7
         L     7,36(4)
         SR    7,2
         LR    2,7
         AR    2,5
         CR    6,3
         BL    @@L17
         CR    6,2
         BNL   @@L17
         SR    6,5
         AR    15,6
         ST    15,32(4)
         B     @@L13
@@L17    EQU   *
         L     12,0(,10)
         CR    6,5
         BNL   @@L22
         LA    3,104(,13)
         LR    2,4
         A     2,=F'43'
         CLI   52(4),64
         BNH   @@L23
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    2,96(13)
         A     4,=F'52'
         ST    4,100(13)
         A     4,=F'-52'
         B     @@L43
@@L23    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC1)
         ST    2,96(13)
@@L43    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LA    2,104(,13)
         ST    2,88(13)
         A     4,=F'106'
         ST    4,92(13)
         A     4,=F'-106'
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(@@REOPEN)
         BALR  14,15
         LTR   15,15
         BE    @@L13
         SLR   5,5
@@L22    EQU   *
         L     12,0(,10)
         LH    2,40(4)
         N     2,=F'512'
         LR    3,5
         LTR   2,2
         BE    @@L45
         LR    3,5
@@L44    EQU   *
         CR    3,6
         BNL   @@L13
         LA    2,368(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'1000'
         MVC   96(4,13),=F'1'
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(@@FREAD)
         BALR  14,15
         A     3,=F'1'
         B     @@L44
@@L42    EQU   *
         OC    40(2,4),=H'3'
         B     @@L13
@@L45    EQU   *
         L     12,0(,10)
         CR    3,6
         BNL   @@L13
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BE    @@L42
         A     3,=F'1'
         B     @@L45
@@L13    EQU   *
         L     12,0(,10)
         LH    2,40(4)
         N     2,=F'2'
         L     15,=F'-1'
         LTR   2,2
         BNE   @@L1
         ST    15,20(4)
         LR    15,2
@@L1     EQU   *
         L     12,0(,10)
* Function __fseek epilogue
         PDPEPIL
* Function __fseek literal pool
         DS    0F
         LTORG
* Function __fseek page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'plusseek'
         DS    0F
* Function plusseek,F1 prologue
@@F1     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function plusseek code
         L     6,0(11)
         L     7,4(11)
         L     5,8(11)
         LH    3,40(6)
         LR    15,3
         N     15,=XL4'0000FFFF'
         LR    2,15
         N     2,=F'16'
         LTR   2,2
         BE    @@L47
         N     15,=F'32'
         LTR   15,15
         BNE   @@L47
         LR    4,7
         LTR   5,5
         BE    @@L79
         L     4,24(6)
         AR    4,7
         LA    2,2(0,0)
         CLR   5,2
         BH    @@L47
@@L79    EQU   *
         L     12,0(,10)
         SLR   2,2
         CL    4,24(6)
         BE    @@L46
@@L47    EQU   *
         L     12,0(,10)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'32'
         LTR   2,2
         BNE   @@L80
         LA    8,2(0,0)
         CLR   5,8
         BNE   @@L51
         B     @@L53
@@L80    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BNE   @@L46
         B     @@L55
@@L53    EQU   *
         L     12,0(,10)
         N     3,=F'16'
         LTR   3,3
         BNE   @@L55
@@L57    EQU   *
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BNE   @@L57
@@L55    EQU   *
         L     12,0(,10)
         NC    40(2,6),=H'-2'
@@L51    EQU   *
         L     12,0(,10)
         LR    4,7
         LTR   5,5
         BE    @@L61
         LA    8,1(0,0)
         CLR   5,8
         BE    @@L81
         LA    2,2(0,0)
         CR    5,2
         BNE   @@L82
@@L81    EQU   *
         L     12,0(,10)
         L     4,24(6)
         AR    4,7
@@L61    EQU   *
         L     12,0(,10)
         LTR   4,4
         BL    @@L82
         L     3,24(6)
         SLR   2,2
         CLR   4,3
         BE    @@L46
         LH    15,40(6)
         N     15,=F'16'
         LTR   15,15
         BNE   @@L68
         CLR   4,3
         BNH   @@L69
         CLR   3,4
         BNL   @@L74
@@L73    EQU   *
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     8,=F'-1'
         CLR   15,8
         BE    @@L74
         L     2,24(6)
         CLR   2,4
         BL    @@L73
         B     @@L74
@@L69    EQU   *
         L     12,0(,10)
         L     5,32(6)
         LR    2,5
         S     2,28(6)
         LR    7,3
         SR    7,2
         L     2,20(6)
         L     8,=F'-1'
         CR    2,8
         BNE   @@L68
         CR    4,7
         BL    @@L68
         SR    3,4
         SR    5,3
         ST    5,32(6)
         ST    4,24(6)
         LR    2,15
         B     @@L46
@@L68    EQU   *
         L     12,0(,10)
         ST    4,24(6)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BNE   @@L46
@@L74    EQU   *
         L     12,0(,10)
         L     2,24(6)
         LH    3,40(6)
         CLR   2,4
         BE    @@L77
         N     3,=F'-2'
         STH   3,40(6)
@@L82    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         L     2,=F'-1'
         B     @@L46
@@L77    EQU   *
         L     12,0(,10)
         N     3,=F'-2'
         STH   3,40(6)
         SLR   2,2
@@L46    EQU   *
         L     12,0(,10)
         LR    15,2
* Function plusseek epilogue
         PDPEPIL
* Function plusseek literal pool
         DS    0F
         LTORG
* Function plusseek page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
