         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'JES'
         DC    X'0'
         DS    0F
* X-func __listal prologue
@@LISTAL PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __listal code
         L     8,8(11)
         N     8,=F'15'
         SLR   9,9
         ST    9,144(13)
         LR    7,9
         LA    4,104(,13)
         LA    5,36(0,0)
         LR    2,9
         LR    3,9
         MVCL  4,2
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@GTDSAB)
         BALR  14,15
@@L46    EQU   *
         LR    6,15
         LTR   15,15
         BE    @@L23
         L     3,16(15)
         SLR   4,4
         IC    4,12(3)
         SLL   4,16
         SLR   2,2
         IC    2,13(3)
         SLL   2,8
         OR    4,2
         SLR   2,2
         IC    2,14(3)
         OR    4,2
         A     4,=F'16'
         LTR   9,9
         BE    @@L5
         CLI   4(3),64
         BNH   @@L4
@@L5     EQU   *
         L     12,0(,10)
         CLI   4(3),64
         BNH   @@L6
         LTR   8,8
         BE    @@L7
         LR    2,8
         N     2,=F'1'
         LTR   2,2
         BE    @@L8
         IC    2,34(6)
         N     2,=F'68'
         LTR   2,2
         BE    @@L10
@@L8     EQU   *
         L     12,0(,10)
         LR    2,8
         N     2,=F'2'
         LTR   2,2
         BE    @@L11
         IC    2,34(6)
         N     2,=F'168'
         LTR   2,2
         BE    @@L10
@@L11    EQU   *
         L     12,0(,10)
         LR    2,8
         N     2,=F'4'
         LTR   2,2
         BE    @@L13
         IC    2,34(6)
         N     2,=F'14'
         LTR   2,2
         BE    @@L10
@@L13    EQU   *
         L     12,0(,10)
         LR    2,8
         N     2,=F'8'
         LTR   2,2
         BE    @@L7
         IC    2,34(6)
         N     2,=F'1'
         LTR   2,2
         BE    @@L10
@@L7     EQU   *
         L     12,0(,10)
         L     2,8(11)
         N     2,=F'16'
         LTR   2,2
         BE    @@L17
         IC    2,36(6)
         N     2,=F'14'
         LTR   2,2
         BNE   @@L10
@@L17    EQU   *
         L     12,0(,10)
         L     2,8(11)
         N     2,=F'32'
         LTR   2,2
         BE    @@L21
         L     2,=A(@@LC0)
         CLC   48(3,6),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L21
@@L10    EQU   *
         L     12,0(,10)
         LA    9,1(0,0)
         B     @@L4
@@L21    EQU   *
         L     12,0(,10)
         SLR   9,9
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L23
         LA    2,144(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L23
         CLI   4(3),64
         BNH   @@L6
         LR    2,3
         A     2,=F'4'
@@L28    EQU   *
         IC    3,0(2)
         STC   3,0(15,7)
         A     15,=F'1'
         A     2,=F'1'
         CLI   0(2),64
         BNH   @@L6
         LA    3,7(0,0)
         CR    15,3
         BNH   @@L28
@@L6     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'104'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L23
         A     7,=F'12'
         ST    7,88(13)
         A     7,=F'-12'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L23
         IC    3,11(7)
         LA    2,1(,3)
         STC   2,11(7)
         CLI   0(4),64
         BNH   @@L32
         LR    2,4
@@L34    EQU   *
         IC    3,0(2)
         STC   3,0(15,5)
         A     15,=F'1'
         A     2,=F'1'
         CLI   0(2),64
         BNH   @@L32
         LA    3,43(0,0)
         CLR   15,3
         BNH   @@L34
@@L32    EQU   *
         L     12,0(,10)
         SLR   15,15
         CLI   118(4),64
         BNH   @@L36
         LR    2,4
         A     2,=F'118'
         LR    3,5
         A     3,=F'45'
         ST    3,152(13)
@@L38    EQU   *
         L     3,152(13)
         MVC   0(1,3),0(2)
         A     15,=F'1'
         A     3,=F'1'
         ST    3,152(13)
         A     2,=F'1'
         CLI   0(2),64
         BNH   @@L36
         LA    3,5(0,0)
         CLR   15,3
         BNH   @@L38
@@L36    EQU   *
         L     12,0(,10)
         L     2,8(11)
         N     2,=F'256'
         LTR   2,2
         BE    @@L39
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
         LTR   15,15
         BE    @@L4
@@L39    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F4)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@NXDSAB)
         BALR  14,15
         B     @@L46
@@L23    EQU   *
         L     12,0(,10)
         L     15,144(13)
* Function __listal epilogue
         PDPEPIL
* Function __listal literal pool
         DS    0F
         LTORG
* Function __listal page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
@@LC1    EQU   *
         DC    C'IS'
         DC    X'0'
@@LC2    EQU   *
         DC    C'PS'
         DC    X'0'
@@LC3    EQU   *
         DC    C'DA'
         DC    X'0'
@@LC4    EQU   *
         DC    C'PO'
         DC    X'0'
@@LC5    EQU   *
         DC    C'VS'
         DC    X'0'
@@LC6    EQU   *
         DC    C'F'
         DC    X'0'
@@LC7    EQU   *
         DC    C'V'
         DC    X'0'
@@LC8    EQU   *
         DC    C'U'
         DC    X'0'
@@LC9    EQU   *
         DC    C'B'
         DC    X'0'
@@LC10   EQU   *
         DC    C'S'
         DC    X'0'
@@LC11   EQU   *
         DC    C'A'
         DC    X'0'
@@LC12   EQU   *
         DC    C'M'
         DC    X'0'
         DS    0F
* Function get_dscb_values,F3 prologue
@@F3     PDPPRLG CINDEX=1,FRAME=568,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function get_dscb_values code
         L     8,0(11)
         LA    4,104(,13)
         LA    5,146(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         LA    9,104(,13)
         LA    2,256(,13)
         LR    4,2
         LA    5,36(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         CLI   45(8),64
         BH    @@L48
         LA    2,296(,13)
         LR    6,2
         LA    7,268(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         ST    8,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LOCATE)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L55
         MVC   45(7,8),302(13)
         CLI   302(13),64
         BNH   @@L51
         LA    3,302(,13)
         LR    2,8
         A     2,=F'45'
@@L53    EQU   *
         MVC   0(1,2),0(3)
         A     15,=F'1'
         A     2,=F'1'
         A     3,=F'1'
         CLI   0(3),64
         BNH   @@L51
         LA    4,5(0,0)
         CR    15,4
         BNH   @@L53
@@L51    EQU   *
         L     12,0(,10)
         SLR   5,5
         STC   5,45(8,15)
@@L48    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         A     8,=F'45'
         ST    8,92(13)
         A     8,=F'-45'
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(@@DSCBDV)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L55
         LR    3,15
         IC    2,38(9)
         N     2,=F'127'
         LA    5,32(0,0)
         CR    2,5
         BE    @@L60
         BH    @@L62
         LA    5,2(0,0)
         CLR   2,5
         BE    @@L61
         B     @@L57
@@L62    EQU   *
         L     12,0(,10)
         LA    5,64(0,0)
         CLR   2,5
         BE    @@L59
         LA    5,128(0,0)
         CLR   2,5
         BNE   @@L57
         L     3,=A(@@LC1)
         B     @@L57
@@L59    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC2)
         B     @@L57
@@L60    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC3)
         B     @@L57
@@L61    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC4)
@@L57    EQU   *
         L     12,0(,10)
         CLI   39(9),8
         BNE   @@L63
         L     3,=A(@@LC5)
         B     @@L79
@@L63    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L64
@@L79    EQU   *
         L     12,0(,10)
         A     8,=F'52'
         ST    8,88(13)
         A     8,=F'-52'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L64    EQU   *
         L     12,0(,10)
         IC    2,40(9)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L66
         BH    @@L69
         LA    5,64(0,0)
         CLR   2,5
         BE    @@L67
         B     @@L70
@@L69    EQU   *
         L     12,0(,10)
         LA    3,192(0,0)
         CLR   2,3
         BE    @@L68
         B     @@L70
@@L66    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC6)
         B     @@L80
@@L67    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC7)
         B     @@L80
@@L68    EQU   *
         L     12,0(,10)
         L     3,=A(@@LC8)
@@L80    EQU   *
         L     12,0(,10)
         A     8,=F'57'
         ST    8,88(13)
         A     8,=F'-57'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L70    EQU   *
         L     12,0(,10)
         IC    2,40(9)
         N     2,=F'16'
         LTR   2,2
         BE    @@L71
         A     8,=F'57'
         ST    8,88(13)
         A     8,=F'-57'
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L71    EQU   *
         L     12,0(,10)
         IC    2,40(9)
         N     2,=F'8'
         LTR   2,2
         BE    @@L72
         A     8,=F'57'
         ST    8,88(13)
         A     8,=F'-57'
         MVC   92(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L72    EQU   *
         L     12,0(,10)
         IC    2,40(9)
         N     2,=F'4'
         LTR   2,2
         BE    @@L73
         A     8,=F'57'
         ST    8,88(13)
         A     8,=F'-57'
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L73    EQU   *
         L     12,0(,10)
         IC    2,40(9)
         N     2,=F'2'
         LTR   2,2
         BE    @@L74
         A     8,=F'57'
         ST    8,88(13)
         A     8,=F'-57'
         MVC   92(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L74    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,15(9)
         STH   2,62(8)
         MVC   64(2,8),44(9)
         MVC   66(2,8),42(9)
         SLR   3,3
         IC    3,9(9)
         LR    2,3
         AH    2,=H'1900'
         STH   2,68(8)
         CLM   2,3,=H'1979'
         BH    @@L75
         AH    3,=H'2000'
         STH   3,68(8)
@@L75    EQU   *
         L     12,0(,10)
         MVC   70(2,8),10(9)
         LH    2,68(8)
         N     2,=XL4'0000FFFF'
         A     2,=F'-1900'
         ST    2,276(13)
         LH    2,10(9)
         N     2,=XL4'0000FFFF'
         ST    2,268(13)
         LA    5,256(,13)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         IC    3,275(13)
         LA    2,1(,3)
         STC   2,72(8)
         MVC   73(1,8),271(13)
         SLR   3,3
         IC    3,31(9)
         LR    2,3
         AH    2,=H'1900'
         STH   2,74(8)
         CLM   2,3,=H'1979'
         BH    @@L76
         AH    3,=H'2000'
         STH   3,74(8)
@@L76    EQU   *
         L     12,0(,10)
         MVC   76(2,8),32(9)
         SLR   3,3
         LA    2,36(0,0)
         LA    5,256(,13)
         
*** MEMSET ***
         LR    14,5           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LH    2,74(8)
         N     2,=XL4'0000FFFF'
         A     2,=F'-1900'
         ST    2,276(13)
         LH    2,32(9)
         N     2,=XL4'0000FFFF'
         ST    2,268(13)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         IC    3,275(13)
         LA    2,1(,3)
         STC   2,78(8)
         MVC   79(1,8),271(13)
@@L55    EQU   *
         L     12,0(,10)
         LR    15,4
* Function get_dscb_values epilogue
         PDPEPIL
* Function get_dscb_values literal pool
         DS    0F
         LTORG
* Function get_dscb_values page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
@@LC13   EQU   *
         DC    C'???'
         DC    X'0'
@@LC14   EQU   *
         DC    C'NEW'
         DC    X'0'
@@LC15   EQU   *
         DC    C'MOD'
         DC    X'0'
@@LC16   EQU   *
         DC    C'OLD'
         DC    X'0'
@@LC17   EQU   *
         DC    C'SHR'
         DC    X'0'
         DS    0F
* Function get_jfcb_values,F4 prologue
@@F4     PDPPRLG CINDEX=2,FRAME=152,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function get_jfcb_values code
         L     6,0(11)
         L     7,4(11)
         LA    4,96(,13)
         LA    5,36(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         SLR   4,4
         SLR   2,2
         IC    2,98(7)
         LA    3,32(0,0)
         CR    2,3
         BE    @@L85
         BH    @@L87
         LA    5,2(0,0)
         CLR   2,5
         BE    @@L86
         B     @@L82
@@L87    EQU   *
         L     12,0(,10)
         LA    3,64(0,0)
         CLR   2,3
         BE    @@L84
         LA    5,128(0,0)
         CLR   2,5
         BNE   @@L82
         L     4,=A(@@LC1)
         B     @@L82
@@L84    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC2)
         B     @@L82
@@L85    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC3)
         B     @@L82
@@L86    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC4)
@@L82    EQU   *
         L     12,0(,10)
         CLI   99(7),8
         BNE   @@L88
         L     4,=A(@@LC5)
         B     @@L108
@@L88    EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L89
@@L108   EQU   *
         L     12,0(,10)
         A     6,=F'52'
         ST    6,88(13)
         A     6,=F'-52'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L89    EQU   *
         L     12,0(,10)
         IC    2,100(7)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L91
         BH    @@L94
         LA    5,64(0,0)
         CLR   2,5
         BE    @@L92
         B     @@L95
@@L94    EQU   *
         L     12,0(,10)
         LA    3,192(0,0)
         CLR   2,3
         BE    @@L93
         B     @@L95
@@L91    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC6)
         B     @@L109
@@L92    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC7)
         B     @@L109
@@L93    EQU   *
         L     12,0(,10)
         L     4,=A(@@LC8)
@@L109   EQU   *
         L     12,0(,10)
         A     6,=F'57'
         ST    6,88(13)
         A     6,=F'-57'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L95    EQU   *
         L     12,0(,10)
         IC    2,100(7)
         N     2,=F'16'
         LTR   2,2
         BE    @@L96
         A     6,=F'57'
         ST    6,88(13)
         A     6,=F'-57'
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L96    EQU   *
         L     12,0(,10)
         IC    2,100(7)
         N     2,=F'8'
         LTR   2,2
         BE    @@L97
         A     6,=F'57'
         ST    6,88(13)
         A     6,=F'-57'
         MVC   92(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L97    EQU   *
         L     12,0(,10)
         IC    2,100(7)
         N     2,=F'4'
         LTR   2,2
         BE    @@L98
         A     6,=F'57'
         ST    6,88(13)
         A     6,=F'-57'
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L98    EQU   *
         L     12,0(,10)
         IC    2,100(7)
         N     2,=F'2'
         LTR   2,2
         BE    @@L99
         A     6,=F'57'
         ST    6,88(13)
         A     6,=F'-57'
         MVC   92(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(STRCAT)
         BALR  14,15
@@L99    EQU   *
         L     12,0(,10)
         MVC   62(2,6),=H'0'
         MVC   64(2,6),104(7)
         MVC   66(2,6),102(7)
         SLR   3,3
         IC    3,80(7)
         LR    2,3
         AH    2,=H'1900'
         STH   2,68(6)
         CLM   2,3,=H'1979'
         BH    @@L100
         AH    3,=H'2000'
         STH   3,68(6)
@@L100   EQU   *
         L     12,0(,10)
         MVC   70(2,6),81(7)
         LH    2,68(6)
         N     2,=XL4'0000FFFF'
         A     2,=F'-1900'
         ST    2,116(13)
         LH    2,70(6)
         N     2,=XL4'0000FFFF'
         ST    2,108(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         IC    5,115(13)
         LA    2,1(,5)
         STC   2,72(6)
         MVC   73(1,6),111(13)
         LA    2,144(,13)
         ST    2,88(13)
         LA    0,136(,13)
         LA    1,88(,13)
         L     15,=V(TM64TIME)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(TM64LTM)
         BALR  14,15
         L     2,20(15)
         A     2,=F'1900'
         STH   2,74(6)
         IC    3,19(15)
         LA    2,1(,3)
         STC   2,78(6)
         MVC   79(1,6),15(15)
         L     2,28(15)
         A     2,=F'1'
         STH   2,76(6)
         L     4,=A(@@LC13)
         IC    2,87(7)
         LR    3,2
         N     3,=F'192'
         LA    5,128(0,0)
         CR    3,5
         BE    @@L103
         BH    @@L105
         LA    5,64(0,0)
         CLR   3,5
         BE    @@L104
         B     @@L101
@@L105   EQU   *
         L     12,0(,10)
         LA    5,192(0,0)
         CLR   3,5
         BNE   @@L101
         L     4,=A(@@LC14)
         B     @@L101
@@L103   EQU   *
         L     12,0(,10)
         L     4,=A(@@LC15)
         B     @@L101
@@L104   EQU   *
         L     12,0(,10)
         L     4,=A(@@LC16)
@@L101   EQU   *
         L     12,0(,10)
         N     2,=F'8'
         LTR   2,2
         BE    @@L106
         L     4,=A(@@LC17)
@@L106   EQU   *
         L     12,0(,10)
         A     6,=F'93'
         ST    6,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L107   EQU   *
         SLR   15,15
* Function get_jfcb_values epilogue
         PDPEPIL
* Function get_jfcb_values literal pool
         DS    0F
         LTORG
* Function get_jfcb_values page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         END
