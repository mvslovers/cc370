         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'F I L E'
         DC    X'0'
         DS    0F
* X-func fopen prologue
FOPEN    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fopen code
         L     4,0(11)
         L     5,4(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    8,15
         LA    15,1(0,0)
         SLR   7,7
         LTR   4,4
         L     14,=A(@@L76)
         BER   14
         LTR   5,5
         L     14,=A(@@L76)
         BER   14
         ST    15,88(13)
         MVC   92(4,13),=F'192'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         L     14,=A(@@L76)
         BER   14
         SLR   6,6
         L     3,=A(@@LC0)
         IC    2,0(3)
@@L77    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L68
         IC    3,0(6,3)
         STC   3,0(6,7)
         A     6,=F'1'
         L     3,=A(@@LC0)
         IC    2,0(6,3)
         B     @@L77
@@L68    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPMODE)
         BALR  14,15
         LTR   15,15
         L     14,=A(@@L3)
         BNER  14
         LH    2,40(7)
         N     2,=F'4096'
         LTR   2,2
         BE    @@L11
         MVI   42(7),64
         MVC   16(2,7),=H'136'
@@L11    EQU   *
         L     12,0(,10)
         IC    5,0(4)
         LR    2,5
         N     2,=XL4'000000FF'
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'132'
         BNE   @@L12
         SLR   2,2
         IC    2,1(4)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'132'
         BNE   @@L12
         CLI   2(4),122
         BNE   @@L12
         A     4,=F'3'
         LR    6,15
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L14
         SLL   2,24
         SRA   2,24
         C     2,=F'77'
         BE    @@L14
         LR    5,7
         A     5,=F'43'
@@L16    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L14
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L14
         CLM   2,1,=XL1'4D'
         BNE   @@L16
@@L14    EQU   *
         L     12,0(,10)
         CLI   0(4),77
         BNE   @@L22
         SLR   6,6
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L22
         SLL   2,24
         SRA   2,24
         C     2,=F'93'
         BE    @@L22
         LR    5,7
         A     5,=F'52'
@@L21    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L22
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L22
         CLM   2,1,=XL1'5D'
         BNE   @@L21
         B     @@L22
@@L12    EQU   *
         L     12,0(,10)
         CLM   5,1,=XL1'5C'
         BNE   @@L23
         SLR   6,6
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L25
         SLL   2,24
         SRA   2,24
         C     2,=F'77'
         BE    @@L25
         LR    5,7
         A     5,=F'43'
@@L27    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L25
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L25
         CLM   2,1,=XL1'4D'
         BNE   @@L27
@@L25    EQU   *
         L     12,0(,10)
         IC    2,43(7)
         CLM   2,1,=XL1'00'
         BE    @@L28
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPOPEN)
         BALR  14,15
         LTR   15,15
         BE    @@L3
@@L28    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPSTAR)
         BALR  14,15
         B     @@L50
@@L23    EQU   *
         L     12,0(,10)
         SLR   6,6
         CLM   5,1,=XL1'7D'
         BNE   @@L31
         A     4,=F'1'
         B     @@L75
@@L31    EQU   *
         L     12,0(,10)
         CLM   5,1,=XL1'50'
         BE    @@L75
         IC    2,10(8)
         N     2,=F'64'
         LTR   2,2
         BE    @@L75
         LA    1,88(,13)
         L     15,=V(@@GETPFX)
         BALR  14,15
         LTR   15,15
         BE    @@L75
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L37
         LR    5,7
         A     5,=F'61'
@@L39    EQU   *
         SLR   2,2
         IC    2,0(15)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     15,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L37
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L39
@@L37    EQU   *
         L     12,0(,10)
         LA    2,75(0,0)
         STC   2,61(7,6)
         A     6,=F'1'
         LA    2,43(0,0)
         CR    6,2
         BH    @@L41
@@L75    EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L41
         CLM   2,1,=XL1'4D'
         BE    @@L41
         SLL   2,24
         SRA   2,24
         C     2,=F'125'
         BE    @@L41
         LR    15,6
         AR    15,7
         A     15,=F'61'
@@L43    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(15)
         A     6,=F'1'
         A     15,=F'1'
         A     4,=F'1'
         LA    2,43(0,0)
         CR    6,2
         BH    @@L41
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L41
         CLM   2,1,=XL1'4D'
         BE    @@L41
         CLM   2,1,=XL1'7D'
         BNE   @@L43
@@L41    EQU   *
         L     12,0(,10)
         CLI   0(4),77
         BNE   @@L44
         A     4,=F'1'
         SLR   6,6
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L44
         SLL   2,24
         SRA   2,24
         C     2,=F'93'
         BE    @@L44
         LR    5,7
         A     5,=F'52'
@@L48    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     6,=F'1'
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    6,2
         BH    @@L44
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L44
         CLM   2,1,=XL1'5D'
         BNE   @@L48
@@L44    EQU   *
         L     12,0(,10)
         LH    4,40(7)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BE    @@L49
         N     3,=F'4096'
         LTR   3,3
         BNE   @@L49
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPSHR)
         BALR  14,15
         B     @@L50
@@L49    EQU   *
         L     12,0(,10)
         SLR   3,3
         LR    2,4
         N     2,=F'8192'
         LTR   2,2
         BE    @@L51
         CLI   106(7),153
         BNE   @@L51
         LA    3,1(0,0)
@@L51    EQU   *
         L     12,0(,10)
         CLI   61(7),80
         BNE   @@L52
         LTR   3,3
         BNE   @@L52
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPTMP)
         BALR  14,15
         LTR   15,15
         BE    @@L22
@@L52    EQU   *
         L     12,0(,10)
         IC    2,52(7)
         CLM   2,1,=XL1'00'
         BE    @@L54
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPSHR)
         BALR  14,15
         LTR   15,15
         BE    @@L22
@@L54    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPOLD)
         BALR  14,15
         LTR   15,15
         BE    @@L22
         LTR   3,3
         BNE   @@L50
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPNEW)
         BALR  14,15
@@L50    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L3
@@L22    EQU   *
         L     12,0(,10)
         LH    2,40(7)
         N     2,=F'2048'
         LTR   2,2
         BE    @@L59
         CLI   52(7),64
         BNH   @@L59
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
@@L59    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPOPEN)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         LH    2,40(7)
         N     2,=F'32'
         LTR   2,2
         BE    @@L64
         ST    7,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
         LTR   15,15
         BNE   @@L76
         ST    7,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L64
@@L76    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     2,0(15)
         LTR   7,7
         BE    @@L65
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         SLR   7,7
@@L65    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    2,0(15)
@@L64    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L66
         LR    2,8
         A     2,=F'24'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    2,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L66    EQU   *
         L     12,0(,10)
         LR    15,7
* Function fopen epilogue
         PDPEPIL
* Function fopen literal pool
         DS    0F
         LTORG
* Function fopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'appmem'
@@LC1    EQU   *
         DC    C'DD:%.*s(%.*s)'
         DC    X'0'
@@LC2    EQU   *
         DC    C'r'
         DC    X'0'
         DS    0F
* Function appmem,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=136,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function appmem code
         L     3,0(11)
         SLR   4,4
         CLI   43(3),64
         BNH   @@L80
         LR    2,3
         A     2,=F'43'
@@L82    EQU   *
         A     4,=F'1'
         A     2,=F'1'
         LA    5,7(0,0)
         CR    4,5
         BH    @@L80
         CLI   0(2),64
         BH    @@L82
@@L80    EQU   *
         L     12,0(,10)
         SLR   15,15
         CLI   52(3),64
         BNH   @@L84
         LR    2,3
         A     2,=F'52'
@@L86    EQU   *
         A     15,=F'1'
         A     2,=F'1'
         LA    5,7(0,0)
         CR    15,5
         BH    @@L84
         CLI   0(2),64
         BH    @@L86
@@L84    EQU   *
         L     12,0(,10)
         LA    2,112(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC1)
         ST    4,96(13)
         A     3,=F'43'
         ST    3,100(13)
         ST    15,104(13)
         A     3,=F'9'
         ST    3,108(13)
         A     3,=F'-52'
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=A(FOPEN)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L87
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'45'
         LA    15,1(0,0)
         B     @@L78
@@L87    EQU   *
         L     12,0(,10)
         NC    40(2,3),=H'-2089'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    2,0(15)
         LR    15,2
@@L78    EQU   *
         L     12,0(,10)
* Function appmem epilogue
         PDPEPIL
* Function appmem literal pool
         DS    0F
         LTORG
* Function appmem page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
