         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'__listvl'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: out of memory'
         DC    X'0'
         DS    0F
* X-func *@@LISTVL prologue
@@LISTVL PDPPRLG CINDEX=0,FRAME=376,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@LISTVL code
         L     7,0(11)
         L     9,4(11)
         L     8,8(11)
         MVC   368(4,13),=F'0'
         LA    2,16(0,0)
         L     2,0(2)
         L     3,40(2)
         LH    2,0(3)
         CLM   2,3,=H'-1'
         BE    @@L3
         LR    6,3
@@L21    EQU   *
         LH    4,0(6)
         N     4,=XL4'0000FFFF'
         LTR   4,4
         BE    @@L4
         CLI   18(4),32
         BNE   @@L4
         IC    2,19(4)
         SLL   2,24
         SRA   2,24
         C     2,=F'5'
         BE    @@L4
         IC    2,3(4)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L4
         LTR   7,7
         BE    @@L9
         IC    2,0(7)
         CLM   2,1,=XL1'00'
         BE    @@L9
         MVC   104(6,13),28(4)
         MVI   110(13),0
         LA    2,104(,13)
         ST    2,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@PATMAT)
         BALR  14,15
         LTR   15,15
         BE    @@L4
@@L9     EQU   *
         L     12,0(,10)
         MVC   88(4,13),368(13)
         LR    5,4
         A     5,=F'28'
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'40'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L12
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L3
@@L12    EQU   *
         L     12,0(,10)
         LA    2,368(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L13
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L3
@@L13    EQU   *
         L     12,0(,10)
         MVC   0(6,3),0(5)
         IC    2,3(4)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L14
         OI    7(3),128
@@L14    EQU   *
         L     12,0(,10)
         IC    2,3(4)
         N     2,=F'32'
         LTR   2,2
         BE    @@L15
         OI    7(3),64
@@L15    EQU   *
         L     12,0(,10)
         IC    2,3(4)
         N     2,=F'4'
         LTR   2,2
         BE    @@L16
         OI    7(3),32
@@L16    EQU   *
         L     12,0(,10)
         IC    2,34(4)
         N     2,=F'16'
         LTR   2,2
         BE    @@L17
         OI    7(3),8
@@L17    EQU   *
         L     12,0(,10)
         IC    2,34(4)
         N     2,=F'8'
         LTR   2,2
         BE    @@L18
         OI    7(3),4
@@L18    EQU   *
         L     12,0(,10)
         IC    2,34(4)
         N     2,=F'4'
         LTR   2,2
         BE    @@L19
         OI    7(3),2
@@L19    EQU   *
         L     12,0(,10)
         ST    4,8(3)
         MVC   12(2,3),4(4)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         STH   15,14(3)
         LTR   9,9
         BE    @@L4
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         A     6,=F'2'
         LH    2,0(6)
         CLM   2,3,=H'-1'
         BNE   @@L21
@@L3     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L23
         IC    2,0(8)
         CLM   2,1,=XL1'00'
         BE    @@L23
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=A(@@F10)
         BALR  14,15
         LR    8,15
         SLR   2,2
         LA    9,112(,13)
         LR    6,9
         LA    7,256(0,0)
         LR    4,2
         LR    5,2
         MVCL  6,4
         LTR   15,15
         BE    @@L23
         ST    9,88(13)
         MVC   92(4,13),=F'256'
@@L36    EQU   *
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(FGETS)
         BALR  14,15
         LTR   15,15
         BE    @@L35
         ST    9,88(13)
         MVC   92(4,13),368(13)
         LA    1,88(,13)
         L     15,=A(@@F11)
         BALR  14,15
         SLR   3,3
         LA    2,256(0,0)
         
*** MEMSET ***
         LR    14,9           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    9,88(13)
         ST    2,92(13)
         B     @@L36
@@L35    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
@@L23    EQU   *
@@L31    EQU   *
         L     12,0(,10)
         L     15,368(13)
* Function *@@LISTVL epilogue
         PDPEPIL
* Function *@@LISTVL literal pool
         DS    0F
         LTORG
* Function *@@LISTVL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function get_dasdtype,F8 prologue
@@F8     PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function get_dasdtype code
         SLR   15,15
         L     2,0(11)
         SLR   3,3
         IC    3,19(2)
         BCTR  3,0
         LA    2,14(0,0)
         CLR   3,2
         BH    @@L38
         SLL   3,2
         L     2,=A(@@L50)
         L     14,0(3,2)
         BR    14
         DS    0F
         DS    0F
         DS    0F
         LTORG
         DS    0F
@@L50    EQU   *
         DC    A(@@L39)
         DC    A(@@L38)
         DC    A(@@L38)
         DC    A(@@L38)
         DC    A(@@L38)
         DC    A(@@L41)
         DC    A(@@L41)
         DC    A(@@L42)
         DC    A(@@L47)
         DC    A(@@L44)
         DC    A(@@L45)
         DC    A(@@L46)
         DC    A(@@L47)
         DC    A(@@L48)
         DC    A(@@L49)
@@L39    EQU   *
         L     12,0(,10)
         L     15,=F'8977'
         B     @@L38
@@L41    EQU   *
         L     12,0(,10)
         L     15,=F'8965'
         B     @@L38
@@L42    EQU   *
         L     12,0(,10)
         L     15,=F'8980'
         B     @@L38
@@L44    EQU   *
         L     12,0(,10)
         L     15,=F'13120'
         B     @@L38
@@L45    EQU   *
         L     12,0(,10)
         L     15,=F'13136'
         B     @@L38
@@L46    EQU   *
         L     12,0(,10)
         L     15,=F'13173'
         B     @@L38
@@L47    EQU   *
         L     12,0(,10)
         L     15,=F'13104'
         B     @@L38
@@L48    EQU   *
         L     12,0(,10)
         L     15,=F'13184'
         B     @@L38
@@L49    EQU   *
         L     12,0(,10)
         L     15,=F'13200'
@@L38    EQU   *
         L     12,0(,10)
* Function get_dasdtype epilogue
         PDPEPIL
* Function get_dasdtype literal pool
         DS    0F
         LTORG
* Function get_dasdtype page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
@V2      EQU   *
         DC    C'get_lspace'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s: LSPACE RC=%d'
         DC    X'0'
         DS    0F
* Function get_lspace,F9 prologue
@@F9     PDPPRLG CINDEX=2,FRAME=144,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function get_lspace code
         L     4,0(11)
         MVC   136(4,13),=F'0'
         L     3,8(4)
         LA    2,104(,13)
         LR    0,3 UCB address in R0
         LR    1,2 LSPACE parameter area in R1
         SVC   78  Issue SVC 78 LSPACE
         ST    15,136(13) Save LSPACE RC
         L     2,136(13)
         LTR   2,2
         BNE   @@L52
         STC   2,114(13)
         STC   2,119(13)
         STC   2,124(13)
         STC   2,129(13)
         STC   2,134(13)
         LA    2,110(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,16(4)
         LA    2,115(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,20(4)
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,24(4)
         LA    2,125(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,28(4)
         LA    2,130(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         ST    15,32(4)
         B     @@L54
@@L52    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),=A(@V2)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L54    EQU   *
         L     12,0(,10)
         L     15,136(13)
* Function get_lspace epilogue
         PDPEPIL
* Function get_lspace literal pool
         DS    0F
         LTORG
* Function get_lspace page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
@@LC2    EQU   *
         DC    C' '
         DC    X'0'
         DS    0F
* Function get_comment,F11 prologue
@@F11    PDPPRLG CINDEX=3,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function get_comment code
         L     4,0(11)
         SLR   3,3
         LA    2,4(,11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    7,15
         STC   3,6(4)
         STC   3,79(4)
         LA    6,104(,13)
         ST    6,88(13)
         ST    4,92(13)
         MVC   96(4,13),=F'6'
         LA    1,88(,13)
         L     15,=V(STRNCPY)
         BALR  14,15
         STC   3,110(13)
         ST    6,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    5,3
@@L65    EQU   *
         CLR   5,7
         BNL   @@L64
         LR    3,5
         SLL   3,2
         L     2,4(11)
         L     3,0(3,2)
         LTR   3,3
         BE    @@L58
         L     2,36(3)
         LTR   2,2
         BNE   @@L58
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@PATMAT)
         BALR  14,15
         LTR   15,15
         BE    @@L58
         A     4,=F'39'
         ST    4,88(13)
         A     4,=F'-39'
         LA    1,88(,13)
         L     15,=V(STRDUP)
         BALR  14,15
         ST    15,36(3)
@@L58    EQU   *
         L     12,0(,10)
         A     5,=F'1'
         B     @@L65
@@L64    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function get_comment epilogue
         PDPEPIL
* Function get_comment literal pool
         DS    0F
         LTORG
* Function get_comment page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
@V3      EQU   *
         DC    C'open_vatlst'
         DC    X'0'
@@LC3    EQU   *
         DC    C'SYS1.PARMLIB(%s)'
         DC    X'0'
@@LC4    EQU   *
         DC    C'r'
         DC    X'0'
@@LC5    EQU   *
         DC    C'%s: unable to open "%s"'
         DC    X'0'
         DS    0F
* Function open_vatlst,F10 prologue
@@F10    PDPPRLG CINDEX=4,FRAME=160,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function open_vatlst code
         L     4,0(11)
         SLR   3,3
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L68
         LA    5,104(,13)
         ST    5,88(13)
         ST    4,92(13)
         MVC   96(4,13),=F'56'
         LA    1,88(,13)
         L     15,=V(STRNCPY)
         BALR  14,15
         STC   3,159(13)
         LA    3,8(0,0)
         CR    2,3
         BH    @@L70
         ST    4,88(13)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BNE   @@L70
         ST    4,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BNE   @@L70
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC3)
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L70    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L68
         MVC   88(4,13),=A(@@LC5)
         MVC   92(4,13),=A(@V3)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L68    EQU   *
         L     12,0(,10)
         LR    15,3
* Function open_vatlst epilogue
         PDPEPIL
* Function open_vatlst literal pool
         DS    0F
         LTORG
* Function open_vatlst page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         DS    0F
* Function in_vollist,F7 prologue
@@F7     PDPPRLG CINDEX=5,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function in_vollist code
         L     6,4(11)
         SLR   5,5
         ST    11,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,5
         CLR   5,15
         BNL   @@L76
         L     3,0(11)
@@L79    EQU   *
         L     2,0(3)
         CLC   0(6,2),0(6)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L77
         LA    5,1(0,0)
         B     @@L76
@@L77    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         A     3,=F'4'
         CLR   4,15
         BL    @@L79
@@L76    EQU   *
         L     12,0(,10)
         LR    15,5
* Function in_vollist epilogue
         PDPEPIL
* Function in_vollist literal pool
         DS    0F
         LTORG
* Function in_vollist page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         END
