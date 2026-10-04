         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '_out_buffer'
* Program text area
         DS    0F
* Function _out_buffer,F2 prologue
@@F2     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function _out_buffer code
         L     3,0(11)
         L     15,8(11)
         CL    15,12(11)
         BNL   @@L1
         L     2,4(11)
         STC   3,0(15,2)
@@L1     EQU   *
         L     12,0(,10)
* Function _out_buffer epilogue
         PDPEPIL
* Function _out_buffer literal pool
         DS    0F
         LTORG
* Function _out_buffer page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC '_out_null'
         DS    0F
* Function _out_null,F3 prologue
@@F3     PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function _out_null code
* Function _out_null epilogue
         PDPEPIL
* Function _out_null literal pool
         DS    0F
         LTORG
* Function _out_null page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC '_out_char'
         DS    0F
* Function _out_char,F4 prologue
@@F4     PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function _out_char code
         IC    2,3(11)
         CLM   2,1,=XL1'00'
         BE    @@L4
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         N     2,=XL4'000000FF'
         ST    2,88(13)
         MVC   92(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FPUTC)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
* Function _out_char epilogue
         PDPEPIL
* Function _out_char literal pool
         DS    0F
         LTORG
* Function _out_char page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC '_out_fct'
         DS    0F
* Function _out_fct,F5 prologue
@@F5     PDPPRLG CINDEX=3,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function _out_fct code
         L     2,4(11)
         SLR   3,3
         IC    3,3(11)
         ST    3,88(13)
         MVC   92(4,13),4(2)
         L     2,0(2)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
* Function _out_fct epilogue
         PDPEPIL
* Function _out_fct literal pool
         DS    0F
         LTORG
* Function _out_fct page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC '_strlen'
         DS    0F
* Function _strlen,F6 prologue
@@F6     PDPPRLG CINDEX=4,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function _strlen code
         L     3,0(11)
         LR    15,3
         IC    2,0(3)
@@L14    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L13
         A     15,=F'1'
         IC    2,0(15)
         B     @@L14
@@L13    EQU   *
         L     12,0(,10)
         SR    15,3
* Function _strlen epilogue
         PDPEPIL
* Function _strlen literal pool
         DS    0F
         LTORG
* Function _strlen page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         
&FUNC    SETC '_is_digit'
         DS    0F
* Function _is_digit,F7 prologue
@@F7     PDPPRLG CINDEX=5,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function _is_digit code
         SLR   15,15
         IC    3,3(11)
         LA    2,16(,3)
         CLM   2,1,=XL1'09'
         BH    @@L16
         LA    15,1(0,0)
@@L16    EQU   *
         L     12,0(,10)
* Function _is_digit epilogue
         PDPEPIL
* Function _is_digit literal pool
         DS    0F
         LTORG
* Function _is_digit page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         
&FUNC    SETC '_atoi'
         DS    0F
* Function _atoi,F8 prologue
@@F8     PDPPRLG CINDEX=6,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN6
         LTORG
@@FEN6   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG6    EQU   *
         LR    11,1
         L     10,=A(@@PGT6)
* Function _atoi code
         L     6,0(11)
         SLR   3,3
         B     @@L18
@@L20    EQU   *
         LR    2,3
         SLL   2,3
         AR    2,3
         AR    3,2
         AR    3,5
         A     3,=F'-240'
         A     4,=F'1'
         ST    4,0(6)
@@L18    EQU   *
         L     12,0(,10)
         L     4,0(6)
         SLR   5,5
         IC    5,0(4)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   15,15
         BNE   @@L20
         LR    15,3
* Function _atoi epilogue
         PDPEPIL
* Function _atoi literal pool
         DS    0F
         LTORG
* Function _atoi page table
         DS    0F
@@PGT6   EQU   *
         DC    A(@@PG6)
         
&FUNC    SETC '_ntoa_format'
         DS    0F
* Function _ntoa_format,F9 prologue
@@F9     PDPPRLG CINDEX=7,FRAME=120,BASER=12,ENTRY=NO
         B     @@FEN7
         LTORG
@@FEN7   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG7    EQU   *
         LR    11,1
         L     10,=A(@@PGT7)
* Function _ntoa_format code
         L     6,8(11)
         L     5,16(11)
         L     3,20(11)
         L     8,28(11)
         L     15,32(11)
         L     7,36(11)
         L     4,40(11)
         ST    6,104(13)
         LR    9,4
         N     9,=F'2'
         LTR   9,9
         BNE   @@L22
         B     @@L69
@@L68    EQU   *
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L24
         L     2,=F'-16'
         STC   2,0(5,3)
         A     3,=F'1'
@@L69    EQU   *
         L     12,0(,10)
         CLR   3,15
         BL    @@L68
@@L24    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'1'
         ST    2,112(13)
         B     @@L75
@@L70    EQU   *
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L22
         L     2,=F'-16'
         STC   2,0(5,3)
         A     3,=F'1'
         L     2,112(13)
@@L75    EQU   *
         L     12,0(,10)
         LTR   2,2
         BE    @@L22
         CLR   3,7
         BL    @@L70
@@L22    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'16'
         LTR   2,2
         BE    @@L29
         LR    2,4
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L30
         LTR   3,3
         BE    @@L30
         CLR   3,15
         BE    @@L31
         CLR   3,7
         BNE   @@L30
@@L31    EQU   *
         L     12,0(,10)
         BCTR  3,0
         LTR   3,3
         BE    @@L30
         LA    2,16(0,0)
         CLR   8,2
         BNE   @@L30
         BCTR  3,0
         B     @@L66
@@L30    EQU   *
         L     12,0(,10)
         LA    2,16(0,0)
         CLR   8,2
         BNE   @@L35
@@L66    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'32'
         LTR   2,2
         BNE   @@L67
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L67
         L     2,=F'-89'
         B     @@L72
@@L67    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'32'
         LTR   2,2
         BE    @@L34
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L34
         L     2,=F'-25'
         B     @@L72
@@L35    EQU   *
         L     12,0(,10)
         LA    2,2(0,0)
         CLR   8,2
         BNE   @@L34
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L34
         LA    2,99(,2)
@@L72    EQU   *
         L     12,0(,10)
         STC   2,0(5,3)
         A     3,=F'1'
@@L34    EQU   *
         L     12,0(,10)
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L29
         L     2,=F'-16'
         STC   2,0(5,3)
         A     3,=F'1'
@@L29    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L39
         CLR   3,7
         BNE   @@L39
         L     2,24(11)
         LTR   2,2
         BNE   @@L40
         LR    2,4
         N     2,=F'4'
         LTR   2,2
         BNE   @@L40
         LR    2,4
         N     2,=F'8'
         LTR   2,2
         BE    @@L39
@@L40    EQU   *
         L     12,0(,10)
         BCTR  3,0
@@L39    EQU   *
         L     12,0(,10)
         LA    2,31(0,0)
         CLR   3,2
         BH    @@L41
         L     2,24(11)
         LTR   2,2
         BE    @@L42
         LA    2,96(0,0)
         B     @@L73
@@L42    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'4'
         LTR   2,2
         BE    @@L44
         LA    2,78(0,0)
         B     @@L73
@@L44    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'8'
         LTR   2,2
         BE    @@L41
         LA    2,64(0,0)
@@L73    EQU   *
         L     12,0(,10)
         STC   2,0(5,3)
         A     3,=F'1'
@@L41    EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L47
         N     4,=F'1'
         LTR   4,4
         BNE   @@L47
         LR    4,3
         CLR   3,7
         BNL   @@L47
@@L51    EQU   *
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    6,96(13)
         A     6,=F'1'
         MVC   100(4,13),12(11)
         L     2,0(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         A     4,=F'1'
         CLR   4,7
         BL    @@L51
@@L47    EQU   *
         L     12,0(,10)
         SLR   4,4
         CLR   4,3
         BNL   @@L64
         AR    5,3
         BCTR  5,0
@@L55    EQU   *
         SLR   2,2
         IC    2,0(5)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         ST    6,96(13)
         A     6,=F'1'
         MVC   100(4,13),12(11)
         L     2,0(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         A     4,=F'1'
         BCTR  5,0
         CLR   4,3
         BL    @@L55
@@L64    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L56
@@L74    EQU   *
         LR    2,6
         S     2,104(13)
         CLR   2,7
         BNL   @@L56
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    6,96(13)
         A     6,=F'1'
         MVC   100(4,13),12(11)
         L     2,0(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         B     @@L74
@@L56    EQU   *
         L     12,0(,10)
         LR    15,6
* Function _ntoa_format epilogue
         PDPEPIL
* Function _ntoa_format literal pool
         DS    0F
         LTORG
* Function _ntoa_format page table
         DS    0F
@@PGT7   EQU   *
         DC    A(@@PG7)
         
&FUNC    SETC '_ntoa_long'
         DS    0F
* Function _ntoa_long,F10 prologue
@@F10    PDPPRLG CINDEX=8,FRAME=176,BASER=12,ENTRY=NO
         B     @@FEN8
         LTORG
@@FEN8   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG8    EQU   *
         LR    11,1
         L     10,=A(@@PGT8)
* Function _ntoa_long code
         SLR   6,6
         SLR   7,7
         L     9,16(11)
         MVC   168(4,13),=F'0'
         LTR   9,9
         BNE   @@L77
         NC    36(4,11),=F'-17'
@@L77    EQU   *
         L     12,0(,10)
         L     2,36(11)
         N     2,=F'1024'
         LTR   2,2
         BE    @@L80
         LTR   9,9
         BE    @@L78
@@L80    EQU   *
         L     12,0(,10)
         LR    6,9
         L     2,24(11)
         CLR   2,9
         BH    @@L85
         LTR   2,2
         BL    @@L84
         LA    3,1(0,0)
         CLR   2,3
         BE    @@L83
         SRDL  6,32
         DR    6,2
         B     @@L85
@@L83    EQU   *
         L     12,0(,10)
         SLR   6,6
         B     @@L85
@@L84    EQU   *
         L     12,0(,10)
         S     6,24(11)
@@L85    EQU   *
         L     12,0(,10)
         LA    8,136(,13)
         A     8,168(13)
         L     2,168(13)
         A     2,=F'1'
         ST    2,168(13)
         LA    15,240(,6)
         CLM   6,1,=XL1'09'
         BNH   @@L87
         L     2,36(11)
         N     2,=F'32'
         LA    15,183(,6)
         LTR   2,2
         BNE   @@L87
         LA    15,119(,6)
@@L87    EQU   *
         L     12,0(,10)
         STC   15,0(8)
         LR    4,9
         SLR   5,5
         L     3,24(11)
         CLR   3,9
         BH    @@L92
         LTR   3,3
         BL    @@L91
         LA    2,1(0,0)
         CLR   3,2
         BE    @@L90
         SRDL  4,32
         DR    4,3
         B     @@L92
@@L90    EQU   *
         L     12,0(,10)
         LR    5,9
         B     @@L92
@@L91    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L92    EQU   *
         L     12,0(,10)
         LR    9,5
         LTR   5,5
         BE    @@L78
         L     2,168(13)
         LA    3,31(0,0)
         CLR   2,3
         BNH   @@L80
@@L78    EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         MVC   100(4,13),12(11)
         LA    2,136(,13)
         ST    2,104(13)
         MVC   108(4,13),168(13)
         MVC   112(4,13),20(11)
         MVC   116(4,13),24(11)
         MVC   120(4,13),28(11)
         MVC   124(4,13),32(11)
         MVC   128(4,13),36(11)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
* Function _ntoa_long epilogue
         PDPEPIL
* Function _ntoa_long literal pool
         DS    0F
         LTORG
* Function _ntoa_long page table
         DS    0F
@@PGT8   EQU   *
         DC    A(@@PG8)
         
&FUNC    SETC '_ntoa_long_long'
         DS    0F
* Function _ntoa_long_long,F11 prologue
@@F11    PDPPRLG CINDEX=9,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN9
         LTORG
@@FEN9   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG9    EQU   *
         LR    11,1
         L     10,=A(@@PGT9)
* Function _ntoa_long_long code
         SLR   15,15
* Function _ntoa_long_long epilogue
         PDPEPIL
* Function _ntoa_long_long literal pool
         DS    0F
         LTORG
* Function _ntoa_long_long page table
         DS    0F
@@PGT9   EQU   *
         DC    A(@@PG9)
         
&FUNC    SETC '_ftoa'
         DS    0F
@V1      EQU   *
         DC    F'1091567616'
         DC    F'0'
         DC    F'1101004800'
         DC    F'0'
         DC    F'1113849856'
         DC    F'0'
         DC    F'1128169472'
         DC    F'0'
         DC    F'1143410688'
         DC    F'0'
         DC    F'1159227904'
         DC    F'0'
         DC    F'1173627904'
         DC    F'0'
         DC    F'1184405120'
         DC    F'0'
         DC    F'1197432336'
         DC    F'0'
         DC    F'1211865802'
         DC    F'0'
         DS    0F
* Function _ftoa,F12 prologue
@@F12    PDPPRLG CINDEX=10,FRAME=168,BASER=12,ENTRY=NO
         B     @@FEN10
         LTORG
@@FEN10  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG10   EQU   *
         LR    11,1
         L     10,=A(@@PGT10)
* Function _ftoa code
         SLR   2,2
         SLR   3,3
         ST    2,144(13)
         ST    3,4+144(13)
         LR    6,2
         LR    7,3
         ST    2,152(13)
         ST    3,4+152(13)
         ST    2,160(13)
         ST    3,4+160(13)
         LD    4,16(11)
         L     5,24(11)
         MVC   136(4,13),8(11)
         SLR   8,8
         ST    8,140(13)
         LTDR  4,4
         BNL   @@L95
         MVC   140(4,13),=F'1'
         LCDR  4,4
@@L95    EQU   *
         L     12,0(,10)
         L     2,32(11)
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L175
         LA    5,6(0,0)
         B     @@L99
@@L175   EQU   *
         L     12,0(,10)
         LA    3,9(0,0)
         CLR   5,3
         BNH   @@L99
         L     4,=F'-16'
         STC   4,104(8,13)
         A     8,=F'1'
         BCTR  5,0
         LA    2,31(0,0)
         CLR   8,2
         BNH   @@L175
@@L99    EQU   *
         L     12,0(,10)
         LDR   0,4
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     9,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    9,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LDR   2,4
         SDR   2,0
         LR    3,5
         SLL   3,3
         L     2,=A(@V1)
         LD    6,0(3,2)
         MDR   2,6
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     4,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    4,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LTR   4,4
         BNL   @@L101
         AD    0,=D'4.294967296E+9'
@@L101   EQU   *
         L     12,0(,10)
         SDR   2,0
         CD    2,=D'5.0E-1'
         BNH   @@L102
         A     4,=F'1'
         MVC   80(4,13),=XL4'4E000000'
         ST    4,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LTR   4,4
         BNL   @@L105
         AD    0,=D'4.294967296E+9'
@@L105   EQU   *
         L     12,0(,10)
         CDR   0,6
         BL    @@L107
         SLR   4,4
         A     9,=F'1'
         B     @@L107
@@L102   EQU   *
         L     12,0(,10)
         CD    2,=D'5.0E-1'
         BNE   @@L107
         LTR   4,4
         BE    @@L110
         LR    2,4
         N     2,=F'1'
         LTR   2,2
         BE    @@L107
@@L110   EQU   *
         L     12,0(,10)
         A     4,=F'1'
@@L107   EQU   *
         L     12,0(,10)
         SLR   15,15
         CD    4,=D'2.147483647E+9'
         BH    @@L94
         LR    15,5
         LTR   5,5
         BNE   @@L176
         MVC   80(4,13),=XL4'4E000000'
         ST    9,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         SDR   4,0
         CD    4,=D'5.0E-1'
         BH    @@L177
         BNE   @@L119
         LR    2,9
         N     2,=F'1'
         LTR   2,2
         BE    @@L119
@@L177   EQU   *
         L     12,0(,10)
         A     9,=F'1'
         B     @@L119
@@L176   EQU   *
         L     12,0(,10)
         LA    5,31(0,0)
         CLR   8,5
         BH    @@L121
         BCTR  15,0
         ST    4,144(13)
         L     2,144(13)
         L     3,4+144(13)
         SRDL  2,32
         LA    5,10(0,0)
         DR    2,5
         ST    2,144(13)
         ST    3,4+144(13)
         IC    3,147(13)
         LA    2,240(,3)
         STC   2,104(8,13)
         A     8,=F'1'
         LR    6,4
         SRDL  6,32
         DR    6,5
         LR    4,7
         LTR   7,7
         BNE   @@L176
@@L121   EQU   *
         L     12,0(,10)
         LA    2,31(0,0)
         CLR   8,2
         BH    @@L125
         BCTR  15,0
         L     3,=F'-1'
         CLR   15,3
         BE    @@L125
@@L126   EQU   *
         L     4,=F'-16'
         STC   4,104(8,13)
         A     8,=F'1'
         LA    5,31(0,0)
         CLR   8,5
         BH    @@L125
         BCTR  15,0
         L     2,=F'-1'
         CLR   15,2
         BNE   @@L126
@@L125   EQU   *
         L     12,0(,10)
         LA    3,31(0,0)
         CLR   8,3
         BH    @@L119
         LA    4,75(0,0)
         STC   4,104(8,13)
         A     8,=F'1'
@@L119   EQU   *
         L     12,0(,10)
         L     2,32(11)
         N     2,=F'2048'
         LTR   2,2
         BNE   @@L128
         LR    3,2
         CLR   2,8
         BNL   @@L130
         LA    2,104(,13)
@@L133   EQU   *
         CLI   0(2),240
         BNE   @@L130
         A     3,=F'1'
         A     2,=F'1'
         CLR   3,8
         BL    @@L133
@@L130   EQU   *
         L     12,0(,10)
         IC    2,104(13,3)
         CLM   2,1,=XL1'4B'
         BNE   @@L134
         SLR   8,8
         B     @@L139
@@L134   EQU   *
         L     12,0(,10)
         SR    8,3
         LA    6,104(,13)
         LR    7,8
         LR    4,6
         AR    4,3
         LR    5,8
         MVCL  6,4
@@L128   EQU   *
         L     12,0(,10)
         LA    5,31(0,0)
         CLR   8,5
         BH    @@L137
@@L139   EQU   *
         L     12,0(,10)
         ST    9,152(13)
         L     4,152(13)
         L     5,4+152(13)
         SRDA  4,32
         LA    2,10(0,0)
         DR    4,2
         ST    4,152(13)
         ST    5,4+152(13)
         LA    2,240(,4)
         STC   2,104(8,13)
         A     8,=F'1'
         ST    9,160(13)
         L     4,160(13)
         L     5,4+160(13)
         SRDA  4,32
         LA    2,10(0,0)
         DR    4,2
         ST    4,160(13)
         ST    5,4+160(13)
         LR    9,5
         L     3,164(13)
         LTR   3,3
         BE    @@L137
         LA    4,31(0,0)
         CLR   8,4
         BNH   @@L139
@@L137   EQU   *
         L     12,0(,10)
         L     4,32(11)
         N     4,=F'2'
         LTR   4,4
         BNE   @@L140
         L     2,32(11)
         N     2,=F'1'
         LTR   2,2
         BE    @@L140
         CL    8,28(11)
         BNL   @@L140
         LA    5,31(0,0)
         CLR   8,5
         BH    @@L140
@@L143   EQU   *
         L     2,=F'-16'
         STC   2,104(8,13)
         A     8,=F'1'
         CL    8,28(11)
         BNL   @@L140
         LA    3,31(0,0)
         CLR   8,3
         BNH   @@L143
@@L140   EQU   *
         L     12,0(,10)
         CL    8,28(11)
         BNE   @@L144
         L     5,140(13)
         LTR   5,5
         BNE   @@L145
         L     2,32(11)
         N     2,=F'4'
         LTR   2,2
         BNE   @@L145
         L     2,32(11)
         N     2,=F'8'
         LTR   2,2
         BE    @@L144
@@L145   EQU   *
         L     12,0(,10)
         BCTR  8,0
@@L144   EQU   *
         L     12,0(,10)
         LA    2,31(0,0)
         CLR   8,2
         BH    @@L146
         L     3,140(13)
         LTR   3,3
         BE    @@L147
         LA    5,96(0,0)
         STC   5,104(8,13)
         B     @@L178
@@L147   EQU   *
         L     12,0(,10)
         L     2,32(11)
         N     2,=F'4'
         LTR   2,2
         BE    @@L149
         LA    2,78(0,0)
         STC   2,104(8,13)
         B     @@L178
@@L149   EQU   *
         L     12,0(,10)
         L     2,32(11)
         N     2,=F'8'
         LTR   2,2
         BE    @@L146
         LA    3,64(0,0)
         STC   3,104(8,13)
@@L178   EQU   *
         L     12,0(,10)
         A     8,=F'1'
@@L146   EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L152
         NC    32(4,11),=F'1'
         L     5,32(11)
         LTR   5,5
         BNE   @@L152
         LR    3,8
         CL    8,28(11)
         BNL   @@L152
@@L156   EQU   *
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         L     2,8(11)
         A     2,=F'1'
         ST    2,8(11)
         MVC   100(4,13),12(11)
         L     5,0(11)
         LA    1,88(,13)
         LA    15,0(5)
         BALR  14,15
         A     3,=F'1'
         CL    3,28(11)
         BL    @@L156
@@L152   EQU   *
         L     12,0(,10)
         SLR   3,3
@@L179   EQU   *
         CLR   3,8
         BNL   @@L173
         LR    2,8
         SR    2,3
         SLR   5,5
         IC    5,103(2,13)
         ST    5,88(13)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         L     2,8(11)
         A     2,=F'1'
         ST    2,8(11)
         MVC   100(4,13),12(11)
         L     5,0(11)
         LA    1,88(,13)
         LA    15,0(5)
         BALR  14,15
         A     3,=F'1'
         B     @@L179
@@L173   EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L161
@@L180   EQU   *
         L     2,8(11)
         S     2,136(13)
         CL    2,28(11)
         BNL   @@L161
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         L     2,8(11)
         A     2,=F'1'
         ST    2,8(11)
         MVC   100(4,13),12(11)
         L     3,0(11)
         LA    1,88(,13)
         LA    15,0(3)
         BALR  14,15
         B     @@L180
@@L161   EQU   *
         L     12,0(,10)
         L     15,8(11)
@@L94    EQU   *
         L     12,0(,10)
* Function _ftoa epilogue
         PDPEPIL
* Function _ftoa literal pool
         DS    0F
         LTORG
* Function _ftoa page table
         DS    0F
@@PGT10  EQU   *
         DC    A(@@PG10)
         
&FUNC    SETC '_vsnprintf'
         DS    0F
* Function _vsnprintf,F13 prologue
@@F13    PDPPRLG CINDEX=11,FRAME=144,BASER=12,ENTRY=NO
         B     @@FEN11
         LTORG
@@FEN11  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG11   EQU   *
         LR    11,1
         L     10,=A(@@PGT11)
* Function _vsnprintf code
         L     9,0(11)
         MVC   128(4,13),8(11)
         L     5,16(11)
         SLR   7,7
         L     2,4(11)
         LTR   2,2
         BNE   @@L182
         L     9,=A(@@F3)
@@L182   EQU   *
         L     12,0(,10)
         L     2,12(11)
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         L     14,=A(@@L297)
         BER   14
         L     3,12(11)
         IC    2,0(3)
         CLM   2,1,=XL1'6C'
         BE    @@L185
         N     2,=XL4'000000FF'
         L     14,=A(@@L321)
         BR    14
@@L185   EQU   *
         L     12,0(,10)
         A     3,=F'1'
         ST    3,12(11)
         SLR   6,6
@@L310   EQU   *
         L     2,12(11)
         SLR   3,3
         IC    3,0(2)
         LA    4,96(0,0)
         CR    3,4
         BE    @@L191
         BH    @@L196
         LA    15,64(0,0)
         CLR   3,15
         BE    @@L193
         LA    4,78(0,0)
         CLR   3,4
         BE    @@L192
         B     @@L195
@@L196   EQU   *
         L     12,0(,10)
         LA    15,123(0,0)
         CLR   3,15
         BE    @@L194
         LA    4,240(0,0)
         CLR   3,4
         BNE   @@L195
         O     6,=F'1'
         B     @@L312
@@L191   EQU   *
         L     12,0(,10)
         O     6,=F'2'
         B     @@L312
@@L192   EQU   *
         L     12,0(,10)
         O     6,=F'4'
         B     @@L312
@@L193   EQU   *
         L     12,0(,10)
         O     6,=F'8'
         B     @@L312
@@L194   EQU   *
         L     12,0(,10)
         O     6,=F'16'
@@L312   EQU   *
         L     12,0(,10)
         A     2,=F'1'
         ST    2,12(11)
         B     @@L310
@@L195   EQU   *
         L     12,0(,10)
         MVC   132(4,13),=F'0'
         L     3,12(11)
         IC    4,0(3)
         LR    2,4
         N     2,=XL4'000000FF'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   15,15
         BE    @@L197
         LA    2,12(,11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         ST    15,132(13)
         B     @@L198
@@L197   EQU   *
         L     12,0(,10)
         SLL   4,24
         SRA   4,24
         C     4,=F'92'
         BNE   @@L198
         A     5,=F'4'
         L     2,=F'-4'
         L     2,0(2,5)
         ST    2,132(13)
         LTR   2,2
         BNL   @@L201
         O     6,=F'2'
         LCR   2,2
         ST    2,132(13)
@@L201   EQU   *
         L     12,0(,10)
         A     3,=F'1'
         ST    3,12(11)
@@L198   EQU   *
         L     12,0(,10)
         MVC   136(4,13),=F'0'
         L     3,12(11)
         CLI   0(3),75
         BNE   @@L202
         O     6,=F'1024'
         LR    2,3
         A     2,=F'1'
         ST    2,12(11)
         IC    4,0(2)
         LR    2,4
         N     2,=XL4'000000FF'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   15,15
         BE    @@L203
         LA    2,12(,11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         ST    15,136(13)
         B     @@L202
@@L203   EQU   *
         L     12,0(,10)
         SLL   4,24
         SRA   4,24
         C     4,=F'92'
         BNE   @@L202
         A     5,=F'4'
         L     2,=F'-4'
         L     2,0(2,5)
         LTR   2,2
         BNH   @@L207
         ST    2,136(13)
@@L207   EQU   *
         L     12,0(,10)
         A     3,=F'2'
         ST    3,12(11)
@@L202   EQU   *
         L     12,0(,10)
         L     3,12(11)
         SLR   2,2
         IC    2,0(3)
         LA    15,145(0,0)
         CR    2,15
         BE    @@L214
         BH    @@L216
         LA    4,136(0,0)
         CLR   2,4
         BE    @@L211
         B     @@L208
@@L216   EQU   *
         L     12,0(,10)
         LA    15,147(0,0)
         CLR   2,15
         BE    @@L209
         LA    4,169(0,0)
         CLR   2,4
         BE    @@L214
         B     @@L208
@@L209   EQU   *
         L     12,0(,10)
         O     6,=F'256'
         LR    2,3
         A     2,=F'1'
         ST    2,12(11)
         CLI   0(2),147
         BNE   @@L208
         O     6,=F'512'
         B     @@L323
@@L211   EQU   *
         L     12,0(,10)
         O     6,=F'128'
         LR    2,3
         A     2,=F'1'
         ST    2,12(11)
         CLI   0(2),136
         BNE   @@L208
         O     6,=F'64'
@@L323   EQU   *
         L     12,0(,10)
         A     3,=F'2'
         B     @@L313
@@L214   EQU   *
         L     12,0(,10)
         O     6,=F'256'
         A     3,=F'1'
@@L313   EQU   *
         L     12,0(,10)
         ST    3,12(11)
@@L208   EQU   *
         L     12,0(,10)
         L     3,12(11)
         SLR   2,2
         IC    2,0(3)
         LA    15,150(0,0)
         CR    2,15
         BE    @@L224
         BH    @@L289
         LA    4,132(0,0)
         CR    2,4
         BE    @@L224
         BH    @@L290
         LA    15,130(0,0)
         CR    2,15
         BE    @@L224
         BH    @@L262
         LA    4,108(0,0)
         CLR   2,4
         L     14,=A(@@L321)
         BER   14
         L     14,=A(@@L288)
         BR    14
@@L290   EQU   *
         L     12,0(,10)
         LA    15,134(0,0)
         CR    2,15
         L     14,=A(@@L288)
         BLR   14
         LA    4,135(0,0)
         LA    15,137(0,0)
         CR    2,4
         BH    @@L320
         B     @@L259
@@L289   EQU   *
         L     12,0(,10)
         LA    4,167(0,0)
         CR    2,4
         BE    @@L224
         BH    @@L291
         LA    15,162(0,0)
         CR    2,15
         BE    @@L271
         BH    @@L292
         LA    4,151(0,0)
         CLR   2,4
         L     14,=A(@@L286)
         BER   14
         L     14,=A(@@L288)
         BR    14
@@L292   EQU   *
         L     12,0(,10)
         LA    15,164(0,0)
@@L320   EQU   *
         L     12,0(,10)
         CLR   2,15
         BE    @@L224
         L     14,=A(@@L288)
         BR    14
@@L291   EQU   *
         L     12,0(,10)
         LA    4,198(0,0)
         CR    2,4
         L     14,=A(@@L288)
         BLR   14
         LA    15,199(0,0)
         CR    2,15
         BNH   @@L259
         LA    4,231(0,0)
         CLR   2,4
         L     14,=A(@@L288)
         BNER  14
@@L224   EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'A7'
         BE    @@L226
         CLM   2,1,=XL1'E7'
         BNE   @@L225
@@L226   EQU   *
         L     12,0(,10)
         LA    4,16(0,0)
         B     @@L227
@@L225   EQU   *
         L     12,0(,10)
         LA    4,8(0,0)
         CLM   2,1,=XL1'96'
         BE    @@L227
         LA    4,2(0,0)
         CLM   2,1,=XL1'82'
         BE    @@L227
         LA    4,10(0,0)
         N     6,=F'-17'
@@L227   EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'E7'
         BNE   @@L232
         O     6,=F'32'
         B     @@L305
@@L232   EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'89'
         BE    @@L233
         CLM   2,1,=XL1'84'
         BE    @@L233
@@L305   EQU   *
         L     12,0(,10)
         N     6,=F'-13'
@@L233   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'1024'
         LTR   2,2
         BE    @@L234
         N     6,=F'-2'
@@L234   EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'89'
         BE    @@L236
         CLM   2,1,=XL1'84'
         BNE   @@L235
@@L236   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'512'
         LTR   2,2
         L     14,=A(@@L322)
         BNER  14
         LR    2,6
         N     2,=F'256'
         LTR   2,2
         BE    @@L239
         A     5,=F'4'
         B     @@L327
@@L239   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'64'
         LTR   2,2
         BE    @@L242
         A     5,=F'4'
         L     2,=F'-4'
         SLR   3,3
         IC    3,3(2,5)
         B     @@L243
@@L242   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'128'
         LR    3,5
         A     3,=F'4'
         LR    5,3
         LTR   2,2
         BE    @@L327
         LR    5,3
         L     2,=F'-4'
         LH    3,2(2,3)
         B     @@L243
@@L327   EQU   *
         L     12,0(,10)
         L     2,=F'-4'
         L     3,0(2,5)
@@L243   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         MVC   100(4,13),128(13)
         LPR   2,3
         ST    2,104(13)
         SRL   3,31
         B     @@L324
@@L235   EQU   *
         L     12,0(,10)
         LR    3,6
         N     3,=F'512'
         LTR   3,3
         L     14,=A(@@L322)
         BNER  14
         LR    2,6
         N     2,=F'256'
         LTR   2,2
         BE    @@L250
         ST    9,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         MVC   100(4,13),128(13)
         A     5,=F'4'
         L     2,=F'-4'
         L     2,0(2,5)
         ST    2,104(13)
@@L324   EQU   *
         L     12,0(,10)
         ST    3,108(13)
         B     @@L314
@@L250   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'64'
         LTR   2,2
         BE    @@L252
         A     5,=F'4'
         L     2,=F'-4'
         SLR   15,15
         IC    15,3(2,5)
         LR    2,15
         B     @@L253
@@L252   EQU   *
         L     12,0(,10)
         LR    2,6
         N     2,=F'128'
         LR    3,5
         A     3,=F'4'
         LTR   2,2
         BE    @@L254
         LR    5,3
         L     2,=F'-4'
         LH    2,2(2,3)
         N     2,=XL4'0000FFFF'
         B     @@L253
@@L254   EQU   *
         L     12,0(,10)
         LR    5,3
         L     2,=F'-4'
         L     2,0(2,3)
@@L253   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         MVC   100(4,13),128(13)
         ST    2,104(13)
         MVC   108(4,13),=F'0'
@@L314   EQU   *
         L     12,0(,10)
         ST    4,112(13)
         MVC   116(4,13),136(13)
         MVC   120(4,13),132(13)
@@L328   EQU   *
         ST    6,124(13)
         LA    1,88(,13)
         L     15,=A(@@F10)
         BALR  14,15
@@L326   EQU   *
         LR    7,15
         B     @@L322
@@L259   EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'86'
         BE    @@L261
         CLM   2,1,=XL1'C6'
         BNE   @@L260
@@L261   EQU   *
         L     12,0(,10)
         O     6,=F'2048'
@@L260   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         MVC   100(4,13),128(13)
         A     5,=F'8'
         L     2,=F'-8'
         LD    0,0(2,5)
         STD   0,104(13)
         MVC   112(4,13),136(13)
         MVC   116(4,13),132(13)
         ST    6,120(13)
         LA    1,88(,13)
         L     15,=A(@@F12)
         BALR  14,15
         B     @@L326
@@L262   EQU   *
         L     12,0(,10)
         LA    3,1(0,0)
         LR    4,6
         N     4,=F'2'
         LTR   4,4
         BNE   @@L263
         LR    2,3
         LA    3,2(0,0)
@@L315   EQU   *
         CL    2,132(13)
         BNL   @@L263
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         LR    2,3
         A     3,=F'1'
         B     @@L315
@@L263   EQU   *
         L     12,0(,10)
         A     5,=F'4'
         L     2,=F'-4'
         SLR   6,6
         IC    6,3(2,5)
         ST    6,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         LTR   4,4
         BE    @@L322
@@L316   EQU   *
         LR    2,3
         A     3,=F'1'
         CL    2,132(13)
         BNL   @@L322
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         B     @@L316
@@L271   EQU   *
         L     12,0(,10)
         A     5,=F'4'
         L     2,=F'-4'
         L     4,0(2,5)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LR    3,15
         LR    8,6
         N     8,=F'1024'
         LTR   8,8
         BE    @@L272
         CL    15,136(13)
         BNH   @@L272
         L     3,136(13)
@@L272   EQU   *
         L     12,0(,10)
         N     6,=F'2'
         LTR   6,6
         BNE   @@L274
@@L317   EQU   *
         LR    2,3
         A     3,=F'1'
         CL    2,132(13)
         BNL   @@L274
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         B     @@L317
@@L274   EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L279
         LTR   8,8
         BE    @@L311
         L     15,136(13)
         BCTR  15,0
         ST    15,136(13)
         L     2,=F'-1'
         CLR   15,2
         BE    @@L279
@@L311   EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(4)
         ST    2,88(13)
         A     4,=F'1'
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         B     @@L274
@@L279   EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L322
@@L319   EQU   *
         LR    2,3
         A     3,=F'1'
         CL    2,132(13)
         BNL   @@L322
         MVC   88(4,13),=F'64'
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         B     @@L319
@@L286   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         MVC   100(4,13),128(13)
         A     5,=F'4'
         L     2,=F'-4'
         L     2,0(2,5)
         ST    2,104(13)
         MVC   108(4,13),=F'0'
         MVC   112(4,13),=F'16'
         MVC   116(4,13),136(13)
         MVC   120(4,13),=F'8'
         O     6,=F'33'
         B     @@L328
@@L288   EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(3)
@@L321   EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         ST    7,96(13)
         A     7,=F'1'
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
@@L322   EQU   *
         L     12,0(,10)
         L     2,12(11)
         A     2,=F'1'
         ST    2,12(11)
         B     @@L182
@@L297   EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         MVC   92(4,13),4(11)
         LR    2,7
         CL    7,128(13)
         BL    @@L295
         L     2,128(13)
         BCTR  2,0
@@L295   EQU   *
         L     12,0(,10)
         ST    2,96(13)
         MVC   100(4,13),128(13)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         LR    15,7
* Function _vsnprintf epilogue
         PDPEPIL
* Function _vsnprintf literal pool
         DS    0F
         LTORG
* Function _vsnprintf page table
         DS    0F
@@PGT11  EQU   *
         DC    A(@@PG11)
* Program data area
         DS    0F
@V2      EQU   *
         DC    A(@@F2)
         DC    A(@@F3)
         DC    A(@@F4)
         DC    A(@@F5)
         DC    A(@@F6)
         DC    A(@@F7)
         DC    A(@@F8)
         DC    A(@@F9)
         DC    A(@@F10)
         DC    A(@@F11)
         DC    A(@@F12)
         DC    A(@@F13)
* X-var __prtfx
         ENTRY @@PRTFX
         DS    0F
@@PRTFX  EQU   *
         DC    A(@V2)
         END
