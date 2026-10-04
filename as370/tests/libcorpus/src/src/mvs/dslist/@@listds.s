         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __listds prologue
@@LISTDS PDPPRLG CINDEX=0,FRAME=592,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __listds code
         L     2,0(11)
         L     3,4(11)
         LA    6,104(,13)
         LA    7,484(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         ST    2,104(13)
         ST    3,108(13)
         MVC   112(4,13),8(11)
         ST    2,88(13)
         ST    3,92(13)
         MVC   96(4,13),=A(@@F3)
         LA    2,104(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@LISTC)
         BALR  14,15
         L     3,172(13)
         LTR   3,3
         BE    @@L2
         L     2,180(13)
         LTR   2,2
         BNE   @@L2
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         L     15,116(13)
* Function __listds epilogue
         PDPEPIL
* Function __listds literal pool
         DS    0F
         LTORG
* Function __listds page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
@@LC0    EQU   *
         DC    C' -'
         DC    X'15'
         DC    X'0'
@@LC1    EQU   *
         DC    C'NONVSAM'
         DC    X'0'
@@LC2    EQU   *
         DC    C'PAGESPACE'
         DC    X'0'
@@LC3    EQU   *
         DC    C'CLUSTER'
         DC    X'0'
@@LC4    EQU   *
         DC    C'USERCATALOG'
         DC    X'0'
@@LC5    EQU   *
         DC    C'IN'
         DC    X'0'
@@LC6    EQU   *
         DC    C'CAT'
         DC    X'0'
@@LC7    EQU   *
         DC    C'VOLSER'
         DC    X'0'
@@LC8    EQU   *
         DC    C'******'
         DC    X'0'
@@LC9    EQU   *
         DC    C'IS'
         DC    X'0'
@@LC10   EQU   *
         DC    C'PS'
         DC    X'0'
@@LC11   EQU   *
         DC    C'DA'
         DC    X'0'
@@LC12   EQU   *
         DC    C'PO'
         DC    X'0'
@@LC13   EQU   *
         DC    C'VS'
         DC    X'0'
@@LC14   EQU   *
         DC    C'F'
         DC    X'0'
@@LC15   EQU   *
         DC    C'V'
         DC    X'0'
@@LC16   EQU   *
         DC    C'U'
         DC    X'0'
@@LC17   EQU   *
         DC    C'B'
         DC    X'0'
@@LC18   EQU   *
         DC    C'S'
         DC    X'0'
@@LC19   EQU   *
         DC    C'A'
         DC    X'0'
@@LC20   EQU   *
         DC    C'M'
         DC    X'0'
@@LC22   EQU   *
         DC    C'3375'
         DC    X'0'
@@LC23   EQU   *
         DC    C'3380'
         DC    X'0'
@@LC21   EQU   *
         DC    C'3350'
         DC    X'0'
@@LC24   EQU   *
         DC    C'3390'
         DC    X'0'
         DS    0F
* Function parse,F3 prologue
@@F3     PDPPRLG CINDEX=1,FRAME=448,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function parse code
         SLR   2,2
         SLR   3,3
         ST    2,432(13)
         ST    3,4+432(13)
         L     6,0(11)
         A     6,=F'80'
         L     3,0(11)
         A     3,=F'336'
         ST    3,416(13)
         SLR   9,9
         LA    4,104(,13)
         LA    5,36(0,0)
         LR    2,9
         LR    3,9
         MVCL  4,2
         ST    6,88(13)
         MVC   92(4,13),4(11)
         LA    2,8(,11)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(VSPRINTF)
         BALR  14,15
         CLI   0(6),241
         L     14,=A(@@L5)
         BER   14
         ST    6,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         SLR   2,2
         IC    2,0(15)
         L     5,=V(@@ISBUF)
         L     3,0(5)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BE    @@L7
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L7
         ST    9,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
@@L7     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BNE   @@L9
@@L10    EQU   *
         L     12,0(,10)
         LR    2,4
         SR    2,6
         LA    6,1(0,0)
         CR    2,6
         BH    @@L9
         L     7,0(11)
         MVI   16(7),0
         MVI   61(7),0
         MVC   72(4,7),=F'0'
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         SLR   2,2
         IC    2,0(15)
         L     3,0(5)
         AR    2,2
         LH    3,0(2,3)
         N     3,=F'8'
         LTR   3,3
         L     14,=A(@@L5)
         BNER  14
         L     2,8(7)
         LTR   2,2
         BE    @@L13
         ST    15,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@PATMAT)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
@@L13    EQU   *
         L     12,0(,10)
         L     2,0(11)
         A     2,=F'16'
         ST    2,88(13)
         A     2,=F'-16'
         ST    2,0(11)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         STC   3,61(2)
         ST    3,72(2)
         L     14,=A(@@L5)
         BR    14
@@L9     EQU   *
         L     12,0(,10)
         L     3,0(11)
         IC    2,16(3)
         CLM   2,1,=XL1'00'
         L     14,=A(@@L5)
         BER   14
@@L16    EQU   *
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BNE   @@L18
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         L     2,68(3)
         LTR   2,2
         BE    @@L22
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LTR   15,15
         BNE   @@L22
         ST    2,72(3)
         L     14,=A(@@L5)
         BR    14
@@L22    EQU   *
         L     12,0(,10)
         L     5,0(11)
         MVC   72(4,5),=F'0'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRDUP)
         BALR  14,15
         LR    4,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         L     3,68(5)
         LTR   3,3
         BE    @@L24
         L     2,76(5)
         LTR   2,2
         BNE   @@L24
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L24    EQU   *
         L     12,0(,10)
         L     6,0(11)
         ST    4,68(6)
         MVC   76(4,6),=F'0'
         ST    4,72(6)
         L     14,=A(@@L5)
         BR    14
@@L18    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC7)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         LTR   15,15
         BNE   @@L25
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         BNE   @@L26
         L     7,0(11)
         STC   15,16(7)
         L     14,=A(@@L5)
         BR    14
@@L26    EQU   *
         L     12,0(,10)
         L     2,0(11)
         A     2,=F'61'
         ST    2,88(13)
         A     2,=F'-61'
         ST    2,0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L25    EQU   *
         L     12,0(,10)
         L     3,0(11)
         IC    2,61(3)
         CLM   2,1,=XL1'00'
         L     14,=A(@@L5)
         BER   14
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'104'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    9,15
         LTR   15,15
         BNE   @@L28
         STC   15,16(3)
         STC   15,61(3)
         L     14,=A(@@L5)
         BR    14
@@L28    EQU   *
         L     12,0(,10)
         ST    15,88(13)
         L     2,0(11)
         A     2,=F'16'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         MVI   0(2),0
         LR    8,9
         A     8,=F'45'
         ST    8,88(13)
         L     2,0(11)
         A     2,=F'61'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         MVI   0(2),0
         L     4,0(11)
         MVC   100(4,9),72(4)
         MVC   72(4,4),=F'0'
         L     2,=A(@@LC8)
         CLC   0(7,8),0(2)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L29
         LA    2,144(,13)
         LR    6,2
         LA    7,268(0,0)
         LR    4,3
         LR    5,3
         MVCL  6,4
         ST    9,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LOCATE)
         BALR  14,15
         LTR   15,15
         BNE   @@L29
         MVC   0(7,8),150(13)
@@L29    EQU   *
         L     12,0(,10)
         ST    9,88(13)
         ST    8,92(13)
         MVC   96(4,13),416(13)
         LA    1,88(,13)
         L     15,=V(@@DSCBDV)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L32)
         BNER  14
         LR    4,15
         L     5,416(13)
         IC    2,38(5)
         N     2,=F'127'
         LA    6,32(0,0)
         CR    2,6
         BE    @@L36
         BH    @@L38
         LA    7,2(0,0)
         CLR   2,7
         BE    @@L37
         B     @@L33
@@L38    EQU   *
         L     12,0(,10)
         LA    3,64(0,0)
         CLR   2,3
         BE    @@L35
         LA    5,128(0,0)
         CLR   2,5
         BNE   @@L33
         L     4,=A(@@LC9)
         B     @@L33
@@L35    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC10)
         B     @@L33
@@L36    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC11)
         B     @@L33
@@L37    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC12)
@@L33    EQU   *
         L     12,0(,10)
         L     6,416(13)
         CLI   39(6),8
         BNE   @@L39
         L     4,=A(@@LC13)
         B     @@L72
@@L39    EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L40
@@L72    EQU   *
         L     12,0(,10)
         A     9,=F'52'
         ST    9,88(13)
         A     9,=F'-52'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L40    EQU   *
         L     12,0(,10)
         L     7,416(13)
         IC    2,40(7)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L42
         BH    @@L45
         LA    4,64(0,0)
         CLR   2,4
         BE    @@L43
         B     @@L46
@@L45    EQU   *
         L     12,0(,10)
         LA    5,192(0,0)
         CLR   2,5
         BE    @@L44
         B     @@L46
@@L42    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC14)
         B     @@L73
@@L43    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC15)
         B     @@L73
@@L44    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC16)
@@L73    EQU   *
         L     12,0(,10)
         A     9,=F'57'
         ST    9,88(13)
         A     9,=F'-57'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L46    EQU   *
         L     12,0(,10)
         L     6,416(13)
         IC    2,40(6)
         N     2,=F'16'
         LTR   2,2
         BE    @@L47
         A     9,=F'57'
         ST    9,88(13)
         A     9,=F'-57'
         MVC   92(4,13),=A(@@LC17)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L47    EQU   *
         L     12,0(,10)
         L     7,416(13)
         IC    2,40(7)
         N     2,=F'8'
         LTR   2,2
         BE    @@L48
         A     9,=F'57'
         ST    9,88(13)
         A     9,=F'-57'
         MVC   92(4,13),=A(@@LC18)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L48    EQU   *
         L     12,0(,10)
         L     3,416(13)
         IC    2,40(3)
         N     2,=F'4'
         LTR   2,2
         BE    @@L49
         A     9,=F'57'
         ST    9,88(13)
         A     9,=F'-57'
         MVC   92(4,13),=A(@@LC19)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L49    EQU   *
         L     12,0(,10)
         L     4,416(13)
         IC    2,40(4)
         N     2,=F'2'
         LTR   2,2
         BE    @@L50
         A     9,=F'57'
         ST    9,88(13)
         A     9,=F'-57'
         MVC   92(4,13),=A(@@LC20)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L50    EQU   *
         L     12,0(,10)
         L     5,416(13)
         SLR   2,2
         IC    2,15(5)
         STH   2,62(9)
         MVC   64(2,9),44(5)
         MVC   66(2,9),42(5)
         MVC   81(1,9),50(5)
         IC    2,50(5)
         N     2,=F'192'
         LA    6,192(0,0)
         CLR   2,6
         BNE   @@L51
         MVI   80(9),195
         B     @@L52
@@L51    EQU   *
         L     12,0(,10)
         MVI   80(9),227
@@L52    EQU   *
         L     12,0(,10)
         L     7,416(13)
         SLR   3,3
         IC    3,51(7)
         SLL   3,16
         SLR   2,2
         IC    2,52(7)
         SLL   2,8
         OR    3,2
         SLL   3,16
         SRA   3,16
         SLR   2,2
         IC    2,53(7)
         OR    3,2
         STH   3,82(9)
         SLR   2,2
         IC    2,54(7)
         SLL   2,8
         SLR   3,3
         IC    3,55(7)
         OR    2,3
         A     2,=F'1'
         STH   2,84(9)
         MVC   420(2,13),=H'0'
         LA    2,144(,13)
         LR    6,2
         LA    7,146(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         ST    8,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@DSCBV)
         BALR  14,15
         LTR   15,15
         BNE   @@L74
         SLR   2,2
         IC    2,164(13)
         SLL   2,8
         LR    3,2
         SLL   3,16
         SRA   3,16
         SLR   2,2
         IC    2,165(13)
         OR    3,2
         CLM   3,3,=H'0'
         BNE   @@L54
@@L74    EQU   *
         L     12,0(,10)
         LA    3,30(0,0)
@@L54    EQU   *
         L     12,0(,10)
         N     3,=XL4'0000FFFF'
         ST    3,424(13)
         LA    2,15(0,0)
         CR    3,2
         BE    @@L60
         BH    @@L61
         LA    4,12(0,0)
         L     2,=A(@@LC22)
         CLR   3,4
         BE    @@L75
         B     @@L60
@@L61    EQU   *
         L     12,0(,10)
         L     6,424(13)
         LA    5,19(0,0)
         L     2,=A(@@LC23)
         CLR   6,5
         BE    @@L75
         LA    7,30(0,0)
         L     2,=A(@@LC21)
         CR    6,7
         BE    @@L75
@@L60    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC24)
@@L75    EQU   *
         L     12,0(,10)
         MVC   88(5,9),0(2)
         SLR   15,15
         L     2,416(13)
         SLR   3,3
         IC    3,15(2)
         ST    3,440(13)
         CR    15,3
         BNL   @@L63
         ST    15,444(13)
@@L65    EQU   *
         L     3,444(13)
         AR    3,15
         A     3,416(13)
         LR    4,3
         A     4,=F'56'
         IC    6,7(4)
         SLL   6,16+8
         SRA   6,16
         LR    8,3
         A     8,=F'57'
         SLR   2,2
         IC    2,7(8)
         OR    6,2
         LR    7,3
         A     7,=F'58'
         IC    5,7(7)
         SLL   5,16+8
         SRA   5,16
         A     3,=F'59'
         SLR   2,2
         IC    2,7(3)
         OR    5,2
         IC    4,11(4)
         SLL   4,16+8
         SRA   4,16
         SLR   2,2
         IC    2,11(8)
         OR    4,2
         IC    2,11(7)
         SLL   2,16+8
         SRA   2,16
         SLR   7,7
         IC    7,11(3)
         OR    2,7
         LH    3,420(13)
         N     3,=XL4'0000FFFF'
         N     4,=XL4'0000FFFF'
         N     6,=XL4'0000FFFF'
         SR    4,6
         ST    4,436(13)
         L     6,432(13)
         L     7,4+432(13)
         L     4,424(13)
         MR    6,4
         ST    6,432(13)
         ST    7,4+432(13)
         N     2,=XL4'0000FFFF'
         N     5,=XL4'0000FFFF'
         SR    2,5
         AR    2,7
         AR    3,2
         A     3,=F'1'
         STH   3,420(13)
         A     15,=F'1'
         L     5,444(13)
         A     5,=F'9'
         ST    5,444(13)
         LA    6,2(0,0)
         CR    15,6
         BH    @@L63
         C     15,440(13)
         BL    @@L65
@@L63    EQU   *
         L     12,0(,10)
         MVC   86(2,9),420(13)
         L     7,416(13)
         SLR   3,3
         IC    3,9(7)
         LR    2,3
         AH    2,=H'1900'
         STH   2,68(9)
         CLM   2,3,=H'1979'
         BH    @@L66
         AH    3,=H'2000'
         STH   3,68(9)
@@L66    EQU   *
         L     12,0(,10)
         L     2,416(13)
         MVC   70(2,9),10(2)
         LH    2,68(9)
         N     2,=XL4'0000FFFF'
         A     2,=F'-1900'
         ST    2,124(13)
         LH    2,70(9)
         N     2,=XL4'0000FFFF'
         ST    2,116(13)
         LA    4,104(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         IC    3,123(13)
         LA    2,1(,3)
         STC   2,72(9)
         MVC   73(1,9),119(13)
         L     5,416(13)
         SLR   3,3
         IC    3,31(5)
         LR    2,3
         AH    2,=H'1900'
         STH   2,74(9)
         CLM   2,3,=H'1979'
         BH    @@L67
         AH    3,=H'2000'
         STH   3,74(9)
@@L67    EQU   *
         L     12,0(,10)
         L     6,416(13)
         MVC   76(2,9),32(6)
         SLR   3,3
         LA    2,36(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LH    2,74(9)
         N     2,=XL4'0000FFFF'
         A     2,=F'-1900'
         ST    2,124(13)
         LH    2,76(9)
         N     2,=XL4'0000FFFF'
         ST    2,116(13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         IC    7,123(13)
         LA    2,1(,7)
         STC   2,78(9)
         MVC   79(1,9),119(13)
@@L32    EQU   *
         L     12,0(,10)
         L     2,0(11)
         A     2,=F'12'
         ST    2,88(13)
         A     2,=F'-12'
         ST    2,0(11)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L69
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L5
@@L69    EQU   *
         L     12,0(,10)
         L     2,100(9)
         LTR   2,2
         BE    @@L5
         L     3,0(11)
         MVC   76(4,3),=F'1'
@@L5     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function parse epilogue
         PDPEPIL
* Function parse literal pool
         DS    0F
         LTORG
* Function parse page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
