         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* Function pddb_end,F7 prologue
@@F7     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function pddb_end code
         L     2,8(11)
         L     15,44(2)
         L     3,4(11)
         A     3,=F'-104'
         CL    15,12(11)
         BL    @@L3
         LR    2,3
         A     2,=F'1'
         CLR   15,2
         BNH   @@L2
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
         A     15,=F'1'
@@L2     EQU   *
         L     12,0(,10)
         A     15,0(11)
* Function pddb_end epilogue
         PDPEPIL
* Function pddb_end literal pool
         DS    0F
         LTORG
* Function pddb_end page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
@@LC0    EQU   *
         DC    C'Unable to allocate storage for %u byte buffer'
         DC    X'0'
@@LC8    EQU   *
         DC    C'Unable to allocate storage for %u byte JESJOB ha'
         DC    C'ndle'
         DC    X'0'
@@LC9    EQU   *
         DC    C'Unable to add %u byte JESJOB handle to array'
         DC    X'0'
@@LC1    EQU   *
         DC    C'JOB'
         DC    X'0'
@@LC2    EQU   *
         DC    C'TSU'
         DC    X'0'
@@LC3    EQU   *
         DC    C'STC'
         DC    X'0'
@@LC4    EQU   *
         DC    C'???'
         DC    X'0'
@@LC5    EQU   *
         DC    C'%s%05u'
         DC    X'0'
@@LC6    EQU   *
         DC    C' '
         DC    X'0'
@@LC7    EQU   *
         DC    C'SYSTEM'
         DC    X'0'
@@LC10   EQU   *
         DC    C'*JESJOB'
         DC    X'0'
@@LC11   EQU   *
         DC    C'UNK%04u'
         DC    X'0'
@@LC12   EQU   *
         DC    C'UNKNOWN.%s.SO%04u'
         DC    X'0'
         DS    0F
* X-func jesjob prologue
JESJOB   PDPPRLG CINDEX=1,FRAME=216,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function jesjob code
         SLR   2,2
         SLR   3,3
         ST    2,192(13)
         ST    3,4+192(13)
         MVC   176(4,13),=F'0'
         SLR   6,6
         L     3,0(11)
         LTR   3,3
         L     14,=A(@@L6)
         BER   14
         L     9,8(3)
         LTR   9,9
         L     14,=A(@@L6)
         BER   14
         L     7,12(3)
         LTR   7,7
         L     14,=A(@@L6)
         BER   14
         L     4,8(11)
         LTR   4,4
         BE    @@L9
         L     2,4(11)
         LTR   2,2
         BE    @@L9
         LR    15,6
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L11
         L     4,4(11)
         LA    5,112(,13)
@@L13    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     15,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L11
         LA    3,11(0,0)
         CLR   15,3
         BNH   @@L13
@@L11    EQU   *
         L     12,0(,10)
         SLR   4,4
         STC   4,112(13,15)
@@L9     EQU   *
         L     12,0(,10)
         LR    2,9
         A     2,=F'20'
         ST    2,184(13)
         MVC   180(4,13),0(7)
         MVC   88(4,13),=F'1'
         LR    3,2
         LH    2,176(2)
         SLL   2,1
         N     2,=F'131070'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L14
         MVC   88(4,13),=A(@@LC0)
         LH    2,176(3)
         SLL   2,1
         N     2,=F'131070'
         ST    2,92(13)
         B     @@L120
@@L108   EQU   *
         MVC   88(4,13),=A(@@LC8)
         MVC   92(4,13),=F'96'
@@L120   EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         L     14,=A(@@L6)
         BR    14
@@L109   EQU   *
         MVC   88(4,13),=A(@@LC9)
         MVC   92(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     14,=A(@@L6)
         BR    14
@@L14    EQU   *
         L     12,0(,10)
         L     4,0(11)
         ST    15,20(4)
         L     2,184(13)
         LH    7,176(2)
         N     7,=XL4'0000FFFF'
         AR    7,15
         L     8,240(9)
         CL    8,244(9)
         L     14,=A(@@L6)
         BNLR  14
         LR    3,8
         A     3,=F'1'
         ST    3,208(13)
@@L94    EQU   *
         L     12,0(,10)
         L     4,208(13)
         IC    2,0(4)
         CLM   2,1,=XL1'FF'
         L     14,=A(@@L17)
         BER   14
         CLM   2,1,=XL1'00'
         L     14,=A(@@L17)
         BER   14
         MVC   88(4,13),180(13)
         MVC   92(4,13),7(4)
         ST    6,96(13)
         L     3,184(13)
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L17)
         BNER  14
         IC    2,58(6)
         L     4,=A(@@LC1)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BL    @@L22
         LR    3,2
         N     3,=XL4'000000FF'
         LR    2,3
         N     2,=F'64'
         L     4,=A(@@LC2)
         LTR   2,2
         BNE   @@L22
         N     3,=F'32'
         L     4,=A(@@LC3)
         LTR   3,3
         BNE   @@L22
         L     4,=A(@@LC4)
@@L22    EQU   *
         L     12,0(,10)
         LA    5,128(,13)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC5)
         ST    4,96(13)
         L     4,208(13)
         LH    2,1(4)
         N     2,=XL4'0000FFFF'
         ST    2,192(13)
         L     2,192(13)
         L     3,4+192(13)
         SRDL  2,32
         L     4,=F'10000'
         DR    2,4
         ST    2,192(13)
         ST    3,4+192(13)
         LH    2,194(13)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LA    4,144(,13)
         ST    4,88(13)
         MVC   92(4,13),=F'12'
         A     8,=F'20'
         ST    8,96(13)
         A     8,=F'-20'
         MVC   100(4,13),=F'8'
         MVC   104(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(MEMCPYP)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         SLR   3,3
         IC    3,58(6)
         LR    2,3
         N     2,=F'64'
         LTR   2,2
         BE    @@L27
         LA    2,160(,13)
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         B     @@L28
@@L27    EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'32'
         LTR   2,2
         BE    @@L29
         L     2,=A(@@LC7)
         MVC   160(7,13),0(2)
         B     @@L28
@@L29    EQU   *
         L     12,0(,10)
         LA    3,160(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'12'
         A     6,=F'440'
         ST    6,96(13)
         A     6,=F'-440'
         MVC   100(4,13),=F'8'
         ST    2,104(13)
         LA    1,88(,13)
         L     15,=V(MEMCPYP)
         BALR  14,15
         CLI   160(13),64
         BNH   @@L31
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         B     @@L28
@@L31    EQU   *
         L     12,0(,10)
         STC   2,160(13)
@@L28    EQU   *
         L     12,0(,10)
         L     2,8(11)
         LTR   2,2
         BE    @@L33
         L     3,4(11)
         LTR   3,3
         BE    @@L33
         LA    3,1(0,0)
         CLR   2,3
         BNE   @@L34
         ST    4,88(13)
         B     @@L112
@@L34    EQU   *
         L     12,0(,10)
         L     2,8(11)
         LA    4,2(0,0)
         CLR   2,4
         BNE   @@L33
         ST    5,88(13)
@@L112   EQU   *
         L     12,0(,10)
         LA    2,112(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@PATMAT)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L17)
         BER   14
@@L33    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L108
         L     3,0(11)
         MVC   16(4,3),=F'0'
         LA    2,176(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L109
         L     2,0(11)
         MVC   16(4,2),176(13)
         L     2,=A(@@LC10)
         MVC   0(8,4),0(2)
         A     4,=F'8'
         ST    4,88(13)
         A     4,=F'-8'
         MVC   92(4,13),=F'9'
         LA    2,144(,13)
         ST    2,96(13)
         ST    15,100(13)
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         LR    2,4
         A     2,=F'17'
         ST    2,200(13)
         ST    2,88(13)
         MVC   92(4,13),=F'9'
         LA    2,128(,13)
         ST    2,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         A     4,=F'26'
         ST    4,88(13)
         A     4,=F'-26'
         MVC   92(4,13),=F'9'
         LA    2,160(,13)
         ST    2,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVC   35(1,4),451(6)
         MVC   36(1,4),99(6)
         L     3,208(13)
         MVC   37(1,4),0(3)
         MVC   38(1,4),3(3)
         MVC   39(1,4),4(3)
         MVC   40(4,4),16(6)
         MVC   44(4,4),12(6)
         MVC   88(4,13),184(6)
         MVC   92(4,13),188(6)
         LR    0,4
         A     0,=F'56'
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         MVC   88(4,13),192(6)
         MVC   92(4,13),196(6)
         LR    0,4
         A     0,=F'64'
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         MVC   72(4,4),8(6)
         MVC   52(4,4),36(6)
         MVC   76(1,4),7(6)
         MVC   88(4,13),428(6)
         MVC   92(4,13),432(6)
         LR    0,4
         A     0,=F'80'
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         MVC   88(4,4),228(6)
         LA    3,4(0,0)
         CLI   91(4),64
         BNE   @@L42
         LR    2,4
         A     2,=F'91'
@@L44    EQU   *
         MVI   0(2),0
         BCTR  3,0
         BCTR  2,0
         LTR   3,3
         BE    @@L42
         CLI   0(2),64
         BE    @@L44
@@L42    EQU   *
         L     12,0(,10)
         L     2,12(11)
         LTR   2,2
         BE    @@L45
         L     2,16(6)
@@L113   EQU   *
         LTR   2,2
         BE    @@L47
         MVC   88(4,13),180(13)
         ST    2,92(13)
         ST    7,96(13)
         L     3,184(13)
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         BNE   @@L47
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    7,88(13)
         ST    2,92(13)
         ST    7,96(13)
         MVC   100(4,13),224(9)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LR    5,15
         LR    3,7
         A     3,224(9)
@@L114   EQU   *
         CLR   3,5
         BNL   @@L51
         LH    2,8(3)
         CLM   2,3,=H'0'
         BE    @@L51
         L     2,4(3)
         LTR   2,2
         BE    @@L52
         MVC   88(4,13),48(4)
         LH    2,8(3)
         N     2,=XL4'0000FFFF'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
         LTR   15,15
         BNE   @@L52
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F10)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L6)
         BER   14
@@L52    EQU   *
         L     12,0(,10)
         A     3,=F'104'
         B     @@L114
@@L51    EQU   *
         L     12,0(,10)
         L     2,16(7)
         B     @@L113
@@L47    EQU   *
         L     12,0(,10)
         L     2,12(6)
@@L115   EQU   *
         LTR   2,2
         BE    @@L45
         MVC   88(4,13),180(13)
         ST    2,92(13)
         ST    7,96(13)
         L     3,184(13)
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         BNE   @@L45
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    7,88(13)
         ST    2,92(13)
         ST    7,96(13)
         MVC   100(4,13),224(9)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LR    5,15
         LR    3,7
         A     3,224(9)
@@L116   EQU   *
         CLR   3,5
         BNL   @@L64
         LH    2,8(3)
         CLM   2,3,=H'0'
         BE    @@L64
         L     2,4(3)
         LTR   2,2
         BE    @@L65
         MVC   88(4,13),48(4)
         LH    2,8(3)
         N     2,=XL4'0000FFFF'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
         LTR   15,15
         BNE   @@L65
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F10)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L6)
         BER   14
@@L65    EQU   *
         L     12,0(,10)
         A     3,=F'104'
         B     @@L116
@@L64    EQU   *
         L     12,0(,10)
         L     2,16(7)
         B     @@L115
@@L45    EQU   *
         L     12,0(,10)
         L     2,12(11)
         LTR   2,2
         BNE   @@L73
         IC    2,58(6)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L72
@@L73    EQU   *
         L     12,0(,10)
         L     2,16(6)
@@L117   EQU   *
         LTR   2,2
         BE    @@L72
         MVC   88(4,13),180(13)
         ST    2,92(13)
         ST    7,96(13)
         L     3,184(13)
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         BNE   @@L72
         LH    2,176(3)
         N     2,=XL4'0000FFFF'
         ST    7,88(13)
         ST    2,92(13)
         ST    7,96(13)
         MVC   100(4,13),224(9)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LR    5,15
         LR    3,7
         A     3,224(9)
@@L118   EQU   *
         CLR   3,5
         BNL   @@L110
         LH    2,8(3)
         CLM   2,3,=H'5'
         BE    @@L111
         A     3,=F'104'
         B     @@L118
@@L111   EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         ST    8,92(13)
         ST    6,96(13)
         MVC   100(4,13),4(3)
         ST    4,104(13)
         LA    1,88(,13)
         L     15,=A(@@F11)
         BALR  14,15
         LTR   15,15
         BNE   @@L72
@@L110   EQU   *
         L     12,0(,10)
         L     2,16(7)
         B     @@L117
@@L72    EQU   *
         L     12,0(,10)
         L     2,48(4)
         LTR   2,2
         BE    @@L17
         LR    2,4
         A     2,=F'48'
         ST    2,204(13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L119   EQU   *
         LTR   5,5
         BE    @@L107
         MVC   88(4,13),204(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L88
         IC    2,8(15)
         CLM   2,1,=XL1'00'
         BE    @@L91
         CLM   2,1,=XL1'40'
         BNE   @@L88
@@L91    EQU   *
         L     12,0(,10)
         A     3,=F'8'
         ST    3,88(13)
         A     3,=F'-8'
         MVC   92(4,13),=A(@@LC11)
         LH    2,94(3)
         N     2,=XL4'0000FFFF'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     3,=F'35'
         ST    3,88(13)
         A     3,=F'-35'
         MVC   92(4,13),=A(@@LC12)
         MVC   96(4,13),200(13)
         LH    2,94(3)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L88    EQU   *
         L     12,0(,10)
         BCTR  5,0
         B     @@L119
@@L107   EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'48'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LA    3,1(0,0)
         CLR   15,3
         BNH   @@L17
         MVC   88(4,13),0(2)
         ST    15,92(13)
         MVC   96(4,13),=F'4'
         MVC   100(4,13),=A(@@F12)
         LA    1,88(,13)
         L     15,=V(QSORT)
         BALR  14,15
@@L17    EQU   *
         L     12,0(,10)
         A     8,=F'28'
         L     4,208(13)
         A     4,=F'28'
         ST    4,208(13)
         CL    8,244(9)
         BL    @@L94
@@L6     EQU   *
         L     12,0(,10)
         L     2,0(11)
         LTR   2,2
         BE    @@L95
         MVC   16(4,2),=F'0'
         MVC   20(4,2),=F'0'
@@L95    EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L96
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L96    EQU   *
         L     12,0(,10)
         L     15,176(13)
* Function jesjob epilogue
         PDPEPIL
* Function jesjob literal pool
         DS    0F
         LTORG
* Function jesjob page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'dsid_comp'
         DS    0F
* Function dsid_comp,F12 prologue
@@F12    PDPPRLG CINDEX=2,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function dsid_comp code
         L     2,0(11)
         L     3,0(2)
         L     2,4(11)
         L     2,0(2)
         LH    15,94(3)
         N     15,=XL4'0000FFFF'
         LH    2,94(2)
         N     2,=XL4'0000FFFF'
         SR    15,2
* Function dsid_comp epilogue
         PDPEPIL
* Function dsid_comp literal pool
         DS    0F
         LTORG
* Function dsid_comp page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC 'process_pddb'
@@LC13   EQU   *
         DC    C'Unable to allocate storage for %u byte JESDD han'
         DC    C'dle'
         DC    X'0'
@@LC14   EQU   *
         DC    C'Unable to add %u byte JESDD handle to job'
         DC    X'0'
@@LC15   EQU   *
         DC    C'*JESDD*'
         DC    X'0'
@@LC16   EQU   *
         DC    C'JESJCLIN'
         DC    X'0'
@@LC18   EQU   *
         DC    C'JESMSGLG'
         DC    X'0'
@@LC20   EQU   *
         DC    C'JESJCL'
         DC    X'0'
@@LC21   EQU   *
         DC    C'JESYSMSG'
         DC    X'0'
@@LC19   EQU   *
         DC    C'JES2.%s.SO%04u'
         DC    X'0'
@@LC22   EQU   *
         DC    C'JESINTXT'
         DC    X'0'
@@LC23   EQU   *
         DC    C'JESJRNL'
         DC    X'0'
@@LC17   EQU   *
         DC    C'JES2.%s.SI%04u'
         DC    X'0'
@@LC24   EQU   *
         DC    C'SYSLOG'
         DC    X'0'
@@LC25   EQU   *
         DC    C'JES%05u'
         DC    X'0'
         DS    0F
* Function process_pddb,F10 prologue
@@F10    PDPPRLG CINDEX=3,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function process_pddb code
         L     5,0(11)
         L     6,4(11)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L123
         MVC   88(4,13),=A(@@LC13)
         MVC   92(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L124
@@L123   EQU   *
         L     12,0(,10)
         A     6,=F'48'
         ST    6,88(13)
         A     6,=F'-48'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L125
         MVC   88(4,13),=A(@@LC14)
         MVC   92(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   4,4
         B     @@L124
@@L125   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC15)
         MVC   0(8,4),0(2)
         LR    7,4
         A     7,=F'8'
         ST    7,88(13)
         MVC   92(4,13),=F'9'
         A     5,=F'36'
         ST    5,96(13)
         A     5,=F'-36'
         MVC   100(4,13),=F'8'
         ST    15,104(13)
         LA    1,88(,13)
         L     15,=V(MEMCPYP)
         BALR  14,15
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LH    15,8(5)
         N     15,=XL4'0000FFFF'
         LR    3,15
         BCTR  3,0
         LA    2,5(0,0)
         CLR   3,2
         BH    @@L133
         SLL   3,2
         LR    15,4
         A     15,=F'35'
         A     6,=F'17'
         L     2,=A(@@L135)
         L     14,0(3,2)
         BR    14
         DS    0F
         DS    0F
         DS    0F
         LTORG
         DS    0F
@@L135   EQU   *
         DC    A(@@L127)
         DC    A(@@L128)
         DC    A(@@L129)
         DC    A(@@L130)
         DC    A(@@L131)
         DC    A(@@L132)
@@L127   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC16)
         B     @@L139
@@L128   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC18)
         B     @@L138
@@L129   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC20)
         MVC   8(7,4),0(2)
         B     @@L137
@@L130   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC21)
@@L138   EQU   *
         L     12,0(,10)
         MVC   8(9,4),0(2)
@@L137   EQU   *
         L     12,0(,10)
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC19)
         ST    6,96(13)
         LH    2,8(5)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         MVI   82(4),192
         B     @@L126
@@L131   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC22)
@@L139   EQU   *
         L     12,0(,10)
         MVC   8(9,4),0(2)
         B     @@L136
@@L132   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC23)
         MVC   8(8,4),0(2)
@@L136   EQU   *
         L     12,0(,10)
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC17)
         ST    6,96(13)
         LH    2,8(5)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         MVI   82(4),160
         B     @@L126
@@L133   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC24)
         CLC   8(7,6),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L126
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC25)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     4,=F'35'
         ST    4,88(13)
         A     4,=F'-35'
         MVC   92(4,13),=A(@@LC19)
         A     6,=F'17'
         ST    6,96(13)
         LH    2,8(5)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L126   EQU   *
         L     12,0(,10)
         MVC   80(1,4),10(5)
         MVC   81(1,4),1(5)
         MVC   84(4,4),4(5)
         MVC   88(4,4),20(5)
         MVC   92(2,4),2(5)
         MVC   94(2,4),8(5)
@@L124   EQU   *
         L     12,0(,10)
         LR    15,4
* Function process_pddb epilogue
         PDPEPIL
* Function process_pddb literal pool
         DS    0F
         LTORG
* Function process_pddb page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC 'make_time'
@@LC26   EQU   *
         DC    C'%X'
         DC    X'0'
         DS    0F
* Function make_time,F8 prologue
@@F8     PDPPRLG CINDEX=4,FRAME=184,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function make_time code
         SLR   6,6
         SLR   7,7
         ST    0,176(13)
         L     9,0(11)
         L     8,4(11)
         SLR   15,15
         LA    4,104(,13)
         LA    5,36(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    3,168(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LTR   9,9
         BE    @@L142
         LTR   8,8
         BE    @@L142
         LR    6,9
         SRDL  6,32
         LA    2,100(0,0)
         DR    6,2
         ST    7,104(13)
         LR    15,8
         SRL   15,16
         LA    2,144(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC26)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,124(13)
         N     8,=F'65535'
         SRL   8,4
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC26)
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,116(13)
         MVC   136(4,13),=F'-1'
         LA    2,104(,13)
         ST    2,88(13)
         LR    0,3
         LA    1,88(,13)
         L     15,=V(TM64MKT)
         BALR  14,15
         L     2,168(13)
         L     4,=F'-1'
         CLR   2,4
         BNE   @@L142
         L     2,172(13)
         CLR   2,4
         BNE   @@L142
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
@@L142   EQU   *
         L     12,0(,10)
         L     2,176(13)
         MVC   0(8,2),168(13)
         LR    15,2
* Function make_time epilogue
         PDPEPIL
* Function make_time literal pool
         DS    0F
         LTORG
* Function make_time page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         
&FUNC    SETC 'intxt_emit'
         DS    0F
* Function intxt_emit,F13 prologue
@@F13    PDPPRLG CINDEX=5,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function intxt_emit code
         L     5,0(11)
         L     2,4(11)
         L     3,8(11)
         LR    4,5
         AR    4,2
         SLR   15,15
         LA    6,3(0,0)
         CLR   2,6
         BNH   @@L145
         IC    2,2(5)
         N     2,=F'15'
         LA    6,2(0,0)
         CR    2,6
         BE    @@L151
         BH    @@L156
         LA    6,1(0,0)
         CLR   2,6
         BE    @@L148
         B     @@L147
@@L156   EQU   *
         L     12,0(,10)
         LA    6,4(0,0)
         CLR   2,6
         BE    @@L152
         LA    6,8(0,0)
         CLR   2,6
         BE    @@L155
         B     @@L147
@@L148   EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         A     3,=F'8'
         ST    3,96(13)
         A     3,=F'-8'
         LR    4,3
         A     4,=F'20'
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=A(@@F14)
         BALR  14,15
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L149
         L     2,0(3)
         A     2,=F'26'
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L149   EQU   *
         L     12,0(,10)
         L     2,4(3)
         L     15,=F'-1'
         LTR   2,2
         BE    @@L145
         B     @@L147
@@L151   EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         A     3,=F'32'
         ST    3,96(13)
         A     3,=F'12'
         ST    3,100(13)
         A     3,=F'12'
         ST    3,104(13)
         B     @@L157
@@L152   EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         LR    6,3
         A     6,=F'68'
         ST    6,96(13)
         LR    5,3
         A     5,=F'80'
         ST    5,100(13)
         LR    4,3
         A     4,=F'136'
         ST    4,104(13)
         LR    7,3
         A     7,=F'144'
         ST    7,108(13)
         LA    1,88(,13)
         L     15,=A(@@F16)
         BALR  14,15
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L153
         L     2,0(3)
         MVC   88(4,13),48(2)
         ST    6,92(13)
         ST    5,96(13)
         ST    4,100(13)
         A     3,=F'32'
         ST    3,104(13)
         A     3,=F'12'
         ST    3,108(13)
         A     3,=F'-44'
         LA    1,88(,13)
         L     15,=A(@@F17)
         BALR  14,15
@@L153   EQU   *
         L     12,0(,10)
         L     2,0(7)
         LTR   2,2
         BE    @@L147
         L     2,0(3)
         MVC   88(4,13),48(2)
         ST    6,92(13)
         ST    5,96(13)
         A     3,=F'32'
         ST    3,100(13)
         A     3,=F'12'
         ST    3,104(13)
         LA    1,88(,13)
         L     15,=A(@@F18)
         BALR  14,15
         B     @@L147
@@L155   EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         A     3,=F'44'
         ST    3,96(13)
         LR    2,3
         A     2,=F'12'
         ST    2,100(13)
         ST    2,104(13)
@@L157   EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=A(@@F15)
         BALR  14,15
@@L147   EQU   *
         L     12,0(,10)
         SLR   15,15
@@L145   EQU   *
         L     12,0(,10)
* Function intxt_emit epilogue
         PDPEPIL
* Function intxt_emit literal pool
         DS    0F
         LTORG
* Function intxt_emit page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         
&FUNC    SETC 'process_intxt'
         DS    0F
* Function process_intxt,F11 prologue
@@F11    PDPPRLG CINDEX=6,FRAME=304,BASER=12,ENTRY=NO
         B     @@FEN6
         LTORG
@@FEN6   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG6    EQU   *
         LR    11,1
         L     10,=A(@@PGT6)
* Function process_intxt code
         L     8,0(11)
         L     2,16(11)
         L     3,12(8)
         MVC   296(4,13),0(3)
         L     9,8(8)
         A     9,=F'20'
         SLR   3,3
         LA    6,112(,13)
         LA    7,32(0,0)
         LR    4,3
         LR    5,3
         MVCL  6,4
         LA    4,144(,13)
         LR    6,4
         LA    7,148(0,0)
         LR    4,3
         LR    5,3
         MVCL  6,4
         LR    5,3
         ST    2,144(13)
         A     2,=F'48'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         ST    15,148(13)
         MVC   88(4,13),=F'1'
         LH    2,176(9)
         N     2,=XL4'0000FFFF'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L160
         ST    15,24(8)
         L     4,12(11)
@@L173   EQU   *
         LTR   4,4
         BE    @@L160
         LR    2,5
         A     5,=F'1'
         L     6,=F'65535'
         CLR   2,6
         BH    @@L160
         MVC   88(4,13),296(13)
         ST    4,92(13)
         ST    3,96(13)
         LH    2,176(9)
         N     2,=XL4'0000FFFF'
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@JSRD4)
         BALR  14,15
         LTR   15,15
         BNE   @@L160
         L     2,4(3)
         L     4,8(11)
         CL    2,8(4)
         BNE   @@L160
         LH    2,8(3)
         CLM   2,3,=H'5'
         BNE   @@L160
         ST    3,88(13)
         LH    2,176(9)
         N     2,=XL4'0000FFFF'
         ST    2,92(13)
         LA    2,112(,13)
         ST    2,96(13)
         MVC   100(4,13),=A(@@F13)
         LA    6,144(,13)
         ST    6,104(13)
         LA    1,88(,13)
         L     15,=V(@@JESPRB)
         BALR  14,15
         LTR   15,15
         BNL   @@L168
         MVC   28(4,8),112(13)
         B     @@L160
@@L168   EQU   *
         L     12,0(,10)
         MVC   28(4,8),112(13)
         L     4,0(3)
         B     @@L173
@@L160   EQU   *
         L     12,0(,10)
         MVC   24(4,8),=F'0'
         MVC   28(4,8),=F'0'
         L     2,112(13)
         LTR   2,2
         BE    @@L170
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L170   EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L171
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L171   EQU   *
         L     12,0(,10)
         L     15,148(13)
* Function process_intxt epilogue
         PDPEPIL
* Function process_intxt literal pool
         DS    0F
         LTORG
* Function process_intxt page table
         DS    0F
@@PGT6   EQU   *
         DC    A(@@PG6)
         
&FUNC    SETC 'process_job'
         DS    0F
* Function process_job,F14 prologue
@@F14    PDPPRLG CINDEX=7,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN7
         LTORG
@@FEN7   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG7    EQU   *
         LR    11,1
         L     10,=A(@@PGT7)
* Function process_job code
         L     7,4(11)
         L     9,8(11)
         L     8,12(11)
         L     6,0(11)
         A     6,=F'6'
         MVI   0(9),0
         MVI   0(8),0
@@L195   EQU   *
         LR    2,6
         A     2,=F'3'
         CLR   2,7
         BH    @@L176
         ST    6,96(13)
         IC    3,0(6)
         CLM   3,1,=XL1'00'
         BE    @@L176
         SLL   3,24
         SRA   3,24
         C     3,=F'-2'
         BE    @@L176
         IC    15,2(6)
         N     15,=F'127'
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L179
         LR    15,2
@@L179   EQU   *
         L     12,0(,10)
         LR    2,6
         AR    2,15
         A     2,=F'3'
         CLR   2,7
         BH    @@L176
         LR    2,3
         N     2,=XL4'000000FF'
         LA    3,165(0,0)
         CLR   2,3
         BE    @@L182
         LA    3,180(0,0)
         CLR   2,3
         BE    @@L183
         B     @@L181
@@L182   EQU   *
         L     12,0(,10)
         LR    4,8
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,0(15,8)
         ST    8,88(13)
         B     @@L192
@@L183   EQU   *
         L     12,0(,10)
         LR    4,9
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   3,3
         STC   3,0(15,9)
         ST    9,88(13)
@@L192   EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
@@L181   EQU   *
         L     12,0(,10)
         A     6,=F'2'
         SLR   3,3
         L     2,96(13)
         SLR   4,4
         IC    4,1(2)
@@L194   EQU   *
         CLR   3,4
         BNL   @@L195
         CLR   6,7
         BNL   @@L195
         IC    2,0(6)
         N     2,=F'127'
         AR    6,2
         A     6,=F'1'
         A     3,=F'1'
         B     @@L194
@@L176   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function process_job epilogue
         PDPEPIL
* Function process_job literal pool
         DS    0F
         LTORG
* Function process_job page table
         DS    0F
@@PGT7   EQU   *
         DC    A(@@PG7)
         
&FUNC    SETC 'process_exec'
         DS    0F
* Function process_exec,F15 prologue
@@F15    PDPPRLG CINDEX=8,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN8
         LTORG
@@FEN8   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG8    EQU   *
         LR    11,1
         L     10,=A(@@PGT8)
* Function process_exec code
         L     7,4(11)
         L     9,8(11)
         L     8,16(11)
         L     6,0(11)
         A     6,=F'4'
         MVI   0(9),0
@@L219   EQU   *
         LR    2,6
         A     2,=F'3'
         CLR   2,7
         BH    @@L198
         ST    6,96(13)
         IC    3,0(6)
         CLM   3,1,=XL1'00'
         BE    @@L198
         SLL   3,24
         SRA   3,24
         C     3,=F'-2'
         BE    @@L198
         IC    15,2(6)
         N     15,=F'127'
         LA    2,8(0,0)
         CR    15,2
         BNH   @@L201
         LR    15,2
@@L201   EQU   *
         L     12,0(,10)
         LR    2,6
         AR    2,15
         A     2,=F'3'
         CLR   2,7
         BH    @@L198
         LR    2,3
         N     2,=XL4'000000FF'
         LA    3,139(0,0)
         CR    2,3
         BE    @@L205
         BH    @@L207
         LA    3,138(0,0)
         CLR   2,3
         BE    @@L204
         B     @@L203
@@L207   EQU   *
         L     12,0(,10)
         LA    3,148(0,0)
         CLR   2,3
         BE    @@L206
         B     @@L203
@@L204   EQU   *
         L     12,0(,10)
         LR    4,8
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,0(15,8)
         ST    8,88(13)
         B     @@L216
@@L205   EQU   *
         L     12,0(,10)
         MVI   0(8),0
         L     4,12(11)
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   2,2
         L     3,12(11)
         STC   2,0(15,3)
         MVC   88(4,13),12(11)
         B     @@L216
@@L206   EQU   *
         L     12,0(,10)
         LR    4,9
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   3,3
         STC   3,0(15,9)
         ST    9,88(13)
@@L216   EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
@@L203   EQU   *
         L     12,0(,10)
         A     6,=F'2'
         SLR   3,3
         L     2,96(13)
         SLR   4,4
         IC    4,1(2)
@@L218   EQU   *
         CLR   3,4
         BNL   @@L219
         CLR   6,7
         BNL   @@L219
         IC    2,0(6)
         N     2,=F'127'
         AR    6,2
         A     6,=F'1'
         A     3,=F'1'
         B     @@L218
@@L198   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function process_exec epilogue
         PDPEPIL
* Function process_exec literal pool
         DS    0F
         LTORG
* Function process_exec page table
         DS    0F
@@PGT8   EQU   *
         DC    A(@@PG8)
         
&FUNC    SETC 'process_dd'
         DS    0F
* Function process_dd,F16 prologue
@@F16    PDPPRLG CINDEX=9,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN9
         LTORG
@@FEN9   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG9    EQU   *
         LR    11,1
         L     10,=A(@@PGT9)
* Function process_dd code
         L     7,4(11)
         L     9,12(11)
         L     8,16(11)
         L     6,0(11)
         A     6,=F'4'
         MVI   0(9),0
         MVI   0(8),0
         L     2,20(11)
         MVC   0(4,2),=F'0'
@@L264   EQU   *
         LR    2,6
         A     2,=F'3'
         CLR   2,7
         BH    @@L233
         ST    6,96(13)
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L233
         CLM   2,1,=XL1'FE'
         BE    @@L233
         N     2,=XL4'000000FF'
         LA    3,74(0,0)
         CR    2,3
         BE    @@L230
         BH    @@L247
         LA    3,36(0,0)
         CLR   2,3
         BE    @@L241
         LA    3,71(0,0)
         CLR   2,3
         BE    @@L242
         B     @@L225
@@L247   EQU   *
         L     12,0(,10)
         LA    3,110(0,0)
         CR    2,3
         BE    @@L226
         BH    @@L248
         LA    3,75(0,0)
         CLR   2,3
         BE    @@L237
         B     @@L225
@@L248   EQU   *
         L     12,0(,10)
         LA    3,131(0,0)
         CLR   2,3
         BE    @@L243
         B     @@L225
@@L226   EQU   *
         L     12,0(,10)
         IC    2,2(6)
         LR    15,2
         N     15,=XL4'000000FF'
         CLM   2,1,=XL1'07'
         BNH   @@L228
         LA    15,8(0,0)
@@L228   EQU   *
         L     12,0(,10)
         LR    2,6
         AR    2,15
         A     2,=F'3'
         CLR   2,7
         BH    @@L225
         L     4,8(11)
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   3,3
         L     2,8(11)
         STC   3,0(15,2)
         MVC   88(4,13),8(11)
         B     @@L260
@@L230   EQU   *
         L     12,0(,10)
         IC    2,2(6)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L231
         A     6,=F'1'
         LR    2,6
         A     2,=F'3'
         CLR   2,7
         BH    @@L233
         ST    6,96(13)
@@L231   EQU   *
         L     12,0(,10)
         IC    2,2(6)
         LR    15,2
         N     15,=XL4'000000FF'
         CLM   2,1,=XL1'2B'
         BNH   @@L235
         LA    15,44(0,0)
@@L235   EQU   *
         L     12,0(,10)
         LR    2,6
         AR    2,15
         A     2,=F'3'
         CLR   2,7
         BH    @@L225
         LR    4,9
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,0(15,9)
         ST    9,88(13)
         B     @@L260
@@L237   EQU   *
         L     12,0(,10)
         IC    2,2(6)
         LR    15,2
         N     15,=XL4'000000FF'
         CLM   2,1,=XL1'03'
         BNH   @@L239
         LA    15,4(0,0)
@@L239   EQU   *
         L     12,0(,10)
         LR    2,6
         AR    2,15
         A     2,=F'3'
         CLR   2,7
         BH    @@L225
         LR    4,8
         LR    5,15
         LR    2,6
         A     2,=F'3'
         LR    3,15
         MVCL  4,2
         SLR   3,3
         STC   3,0(15,8)
         ST    8,88(13)
@@L260   EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         B     @@L225
@@L241   EQU   *
         L     12,0(,10)
         L     2,20(11)
         MVC   0(4,2),=F'1'
         B     @@L225
@@L242   EQU   *
         L     12,0(,10)
         IC    2,2(6)
         N     2,=F'127'
         AR    6,2
         A     6,=F'3'
         B     @@L264
@@L243   EQU   *
         L     12,0(,10)
         LR    3,6
         B     @@L262
@@L258   EQU   *
         CLM   2,1,=XL1'0F'
         BH    @@L245
         N     2,=XL4'000000FF'
         AR    3,2
@@L262   EQU   *
         L     12,0(,10)
         A     3,=F'1'
         CLR   3,7
         BNL   @@L245
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L258
@@L245   EQU   *
         L     12,0(,10)
         LR    6,3
         B     @@L264
@@L225   EQU   *
         L     12,0(,10)
         A     6,=F'2'
         SLR   3,3
         L     2,96(13)
         SLR   4,4
         IC    4,1(2)
@@L263   EQU   *
         CLR   3,4
         BNL   @@L264
         CLR   6,7
         BNL   @@L264
         SLR   2,2
         IC    2,0(6)
         AR    6,2
         A     6,=F'1'
         A     3,=F'1'
         B     @@L263
@@L233   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function process_dd epilogue
         PDPEPIL
* Function process_dd literal pool
         DS    0F
         LTORG
* Function process_dd page table
         DS    0F
@@PGT9   EQU   *
         DC    A(@@PG9)
         
&FUNC    SETC 'process_sysout'
         DS    0F
* Function process_sysout,F17 prologue
@@F17    PDPPRLG CINDEX=10,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN10
         LTORG
@@FEN10  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG10   EQU   *
         LR    11,1
         L     10,=A(@@PGT10)
* Function process_sysout code
         L     6,8(11)
         ST    11,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         ST    6,88(13)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L267
         CLI   1(15),226
         BNE   @@L267
         CLI   2(15),214
         BNE   @@L267
         A     2,=F'3'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         SLL   15,16
         SRA   15,16
         CLM   15,3,=H'0'
         BE    @@L267
         SLR   4,4
@@L279   EQU   *
         CLR   4,5
         BNL   @@L267
         LR    3,4
         SLL   3,2
         L     2,0(11)
         L     3,0(3,2)
         LTR   3,3
         BE    @@L273
         LH    2,94(3)
         STH   15,80(,13)
         CLM   2,3,80(13)
         BNE   @@L273
         A     3,=F'8'
         ST    3,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         MVC   92(4,13),16(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         MVC   92(4,13),20(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         A     3,=F'-35'
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         IC    2,80(3)
         CLM   2,1,=XL1'00'
         BNE   @@L276
         L     2,12(11)
         MVC   80(1,3),0(2)
@@L276   EQU   *
         L     12,0(,10)
         MVI   82(3),64
         B     @@L267
@@L273   EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L279
@@L267   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function process_sysout epilogue
         PDPEPIL
* Function process_sysout literal pool
         DS    0F
         LTORG
* Function process_sysout page table
         DS    0F
@@PGT10  EQU   *
         DC    A(@@PG10)
         
&FUNC    SETC 'process_sysin'
         DS    0F
* Function process_sysin,F18 prologue
@@F18    PDPPRLG CINDEX=11,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN11
         LTORG
@@FEN11  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG11   EQU   *
         LR    11,1
         L     10,=A(@@PGT11)
* Function process_sysin code
         L     6,8(11)
         ST    11,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         ST    6,88(13)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L282
         CLI   1(15),226
         BNE   @@L282
         CLI   2(15),201
         BNE   @@L282
         A     2,=F'3'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         SLL   15,16
         SRA   15,16
         CLM   15,3,=H'0'
         BE    @@L282
         SLR   4,4
@@L293   EQU   *
         CLR   4,5
         BNL   @@L282
         LR    3,4
         SLL   3,2
         L     2,0(11)
         L     3,0(3,2)
         LTR   3,3
         BE    @@L288
         LH    2,94(3)
         STH   15,80(,13)
         CLM   2,3,80(13)
         BNE   @@L288
         A     3,=F'8'
         ST    3,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         MVC   92(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         MVC   92(4,13),16(11)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         A     3,=F'9'
         ST    3,88(13)
         A     3,=F'-35'
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         MVI   82(3),32
         B     @@L282
@@L288   EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L293
@@L282   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function process_sysin epilogue
         PDPEPIL
* Function process_sysin literal pool
         DS    0F
         LTORG
* Function process_sysin page table
         DS    0F
@@PGT11  EQU   *
         DC    A(@@PG11)
         
&FUNC    SETC 'is_dup_dsid'
         DS    0F
* Function is_dup_dsid,F9 prologue
@@F9     PDPPRLG CINDEX=12,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN12
         LTORG
@@FEN12  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG12   EQU   *
         LR    11,1
         L     10,=A(@@PGT12)
* Function is_dup_dsid code
         L     5,4(11)
         ST    11,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   4,4
@@L303   EQU   *
         CLR   4,15
         BNL   @@L302
         LR    3,4
         SLL   3,2
         L     2,0(11)
         L     2,0(3,2)
         LTR   2,2
         BE    @@L297
         LH    2,94(2)
         N     2,=XL4'0000FFFF'
         CLR   2,5
         BNE   @@L297
         LA    15,1(0,0)
         B     @@L294
@@L297   EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L303
@@L302   EQU   *
         L     12,0(,10)
         SLR   15,15
@@L294   EQU   *
         L     12,0(,10)
* Function is_dup_dsid epilogue
         PDPEPIL
* Function is_dup_dsid literal pool
         DS    0F
         LTORG
* Function is_dup_dsid page table
         DS    0F
@@PGT12  EQU   *
         DC    A(@@PG12)
         END
