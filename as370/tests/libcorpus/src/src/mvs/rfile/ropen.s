         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'*RFILE*'
         DC    X'0'
         DS    0F
* X-func ropen prologue
ROPEN    PDPPRLG CINDEX=0,FRAME=440,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ropen code
         L     6,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         ST    15,436(13)
         SLR   15,15
         L     3,4(11)
         LPR   2,3
         LCR   2,2
         SRL   2,31
         ST    2,416(13)
         LR    7,15
         ST    15,420(13)
         ST    15,424(13)
         ST    15,428(13)
         ST    15,432(13)
         LR    9,15
         LA    4,120(,13)
         LA    5,260(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    2,384(,13)
         LR    4,2
         LA    5,9(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    3,400(,13)
         LR    4,3
         LA    5,9(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
@@L86    EQU   *
         CLI   0(6),64
         BNE   @@L66
         A     6,=F'1'
         B     @@L86
@@L66    EQU   *
         L     12,0(,10)
         IC    5,0(6)
         LR    2,5
         N     2,=XL4'000000FF'
         L     8,=V(@@TOUP)
         L     3,0(8)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L6
         SLR   2,2
         IC    2,1(6)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L6
         CLI   2(6),122
         BNE   @@L6
         LR    15,6
         A     15,=F'3'
         SLR   4,4
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L8
         LR    5,15
         LA    6,400(,13)
@@L11    EQU   *
         IC    2,0(5)
         SLL   2,24
         SRA   2,24
         C     2,=F'77'
         BE    @@L8
         N     2,=XL4'000000FF'
         L     3,0(8)
         AR    2,2
         IC    3,1(2,3)
         STC   3,0(6)
         A     4,=F'1'
         A     6,=F'1'
         A     5,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BH    @@L8
         IC    2,0(5)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L11
@@L8     EQU   *
         L     12,0(,10)
         AR    15,4
@@L87    EQU   *
         LA    3,7(0,0)
         CR    4,3
         BH    @@L69
         LA    2,64(0,0)
         STC   2,400(4,13)
         A     4,=F'1'
         B     @@L87
@@L69    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,400(4,13)
         CLI   0(15),77
         BNE   @@L21
         A     15,=F'1'
         SLR   4,4
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L17
         LA    5,384(,13)
@@L20    EQU   *
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'93'
         BE    @@L17
         N     2,=XL4'000000FF'
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    3,1(2,3)
         STC   3,0(5)
         A     4,=F'1'
         A     5,=F'1'
         A     15,=F'1'
         LA    3,7(0,0)
         CR    4,3
         BH    @@L17
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BNE   @@L20
@@L17    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,384(4,13)
         B     @@L21
@@L6     EQU   *
         L     12,0(,10)
         LA    7,1(0,0)
         SLR   4,4
         CLM   5,1,=XL1'7D'
         BNE   @@L22
         AR    6,7
         LR    9,7
         B     @@L23
@@L22    EQU   *
         L     12,0(,10)
         L     3,436(13)
         IC    2,10(3)
         N     2,=F'64'
         LTR   2,2
         BE    @@L23
         LA    1,88(,13)
         L     15,=V(@@GETPFX)
         BALR  14,15
         LTR   15,15
         BE    @@L23
         IC    2,0(15)
         CLM   2,1,=XL1'40'
         BE    @@L27
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L27
         LA    2,120(,13)
@@L29    EQU   *
         MVC   0(1,2),0(15)
         A     4,=F'1'
         A     2,=F'1'
         A     15,=F'1'
         LA    3,7(0,0)
         CR    4,3
         BH    @@L27
         IC    3,0(15)
         CLM   3,1,=XL1'40'
         BE    @@L27
         CLM   3,1,=XL1'00'
         BNE   @@L29
@@L27    EQU   *
         L     12,0(,10)
         LA    2,75(0,0)
         STC   2,120(4,13)
         A     4,=F'1'
@@L23    EQU   *
         L     12,0(,10)
         LA    15,120(,13)
         AR    15,4
         SLR   4,4
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L31
         CLM   2,1,=XL1'4D'
         BE    @@L31
         LTR   9,9
         BE    @@L72
         CLM   2,1,=XL1'7D'
         BE    @@L31
@@L72    EQU   *
         L     12,0(,10)
         LR    5,6
@@L90    EQU   *
         SLR   2,2
         IC    2,0(5)
         L     3,0(8)
         AR    2,2
         IC    3,1(2,3)
         STC   3,0(4,15)
         A     4,=F'1'
         A     5,=F'1'
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L31
         CLM   2,1,=XL1'4D'
         BE    @@L31
         LTR   9,9
         BE    @@L90
         CLM   2,1,=XL1'7D'
         BNE   @@L90
@@L31    EQU   *
         L     12,0(,10)
         SLR   3,3
         STC   3,0(4,15)
         IC    2,0(4,6)
         CLM   2,1,=XL1'4D'
         BNE   @@L35
         LR    15,6
         AR    15,4
@@L88    EQU   *
         A     15,=F'1'
         CLI   0(15),64
         BE    @@L88
         SLR   4,4
         IC    2,0(15)
         CLM   2,1,=XL1'40'
         BE    @@L82
         CLM   2,1,=XL1'00'
         BE    @@L82
         LA    5,384(,13)
@@L43    EQU   *
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'93'
         BE    @@L40
         N     2,=XL4'000000FF'
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    3,1(2,3)
         STC   3,0(5)
         A     4,=F'1'
         A     5,=F'1'
         A     15,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BH    @@L40
         IC    2,0(15)
         CLM   2,1,=XL1'40'
         BE    @@L40
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L43
@@L40    EQU   *
         L     12,0(,10)
         LA    3,7(0,0)
         CR    4,3
         BH    @@L77
@@L82    EQU   *
         L     12,0(,10)
         LA    2,120(,13)
         AR    2,4
         A     2,=F'264'
@@L46    EQU   *
         MVI   0(2),64
         A     4,=F'1'
         A     2,=F'1'
         LA    3,7(0,0)
         CR    4,3
         BNH   @@L46
@@L77    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,384(4,13)
@@L35    EQU   *
         L     12,0(,10)
         LA    3,400(,13)
         ST    3,88(13)
         LA    2,120(,13)
         ST    2,92(13)
         MVC   96(4,13),416(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@FILDEF)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L48
@@L21    EQU   *
         L     12,0(,10)
         MVC   420(4,13),=F'1'
         MVC   424(4,13),=F'255'
         MVC   428(4,13),=F'6233'
         LA    3,400(,13)
         ST    3,88(13)
         LA    2,416(,13)
         ST    2,92(13)
         LA    2,420(,13)
         ST    2,96(13)
         LA    2,424(,13)
         ST    2,100(13)
         LA    2,428(,13)
         ST    2,104(13)
         LA    2,432(,13)
         ST    2,108(13)
         LA    2,384(,13)
         ST    2,112(13)
         LA    1,88(,13)
         L     15,=V(@@AOPEN)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BH    @@L49
         LTR   7,7
         BE    @@L50
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FDCLR)
         BALR  14,15
@@L50    EQU   *
         L     12,0(,10)
         LA    3,1(0,0)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LCR   2,5
         ST    2,0(15)
         B     @@L48
@@L49    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'52'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BNE   @@L51
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         LTR   7,7
         BE    @@L52
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FDCLR)
         BALR  14,15
@@L52    EQU   *
         L     12,0(,10)
         LA    3,1(0,0)
         B     @@L48
@@L51    EQU   *
         L     12,0(,10)
         SLR   4,4
         L     3,=A(@@LC0)
         IC    2,0(3)
@@L89    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L79
         IC    3,0(4,3)
         STC   3,0(4,15)
         A     4,=F'1'
         L     3,=A(@@LC0)
         IC    2,0(4,3)
         B     @@L89
@@L79    EQU   *
         L     12,0(,10)
         ST    7,8(15)
         MVC   12(4,15),420(13)
         MVC   16(4,15),424(13)
         MVC   20(4,15),4(11)
         ST    5,24(15)
         MVC   28(4,15),432(13)
         SLR   4,4
         IC    2,400(13)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L58
         LA    5,400(,13)
         LR    3,15
         A     3,=F'32'
@@L60    EQU   *
         MVC   0(1,3),0(5)
         A     4,=F'1'
         A     3,=F'1'
         A     5,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BH    @@L58
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BNE   @@L60
@@L58    EQU   *
         L     12,0(,10)
         SLR   4,4
         IC    2,384(13)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L62
         LA    5,384(,13)
         LR    3,15
         A     3,=F'41'
@@L64    EQU   *
         MVC   0(1,3),0(5)
         A     4,=F'1'
         A     3,=F'1'
         A     5,=F'1'
         LA    2,7(0,0)
         CR    4,2
         BH    @@L62
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BNE   @@L64
@@L62    EQU   *
         L     12,0(,10)
         L     2,8(11)
         ST    15,0(2)
         SLR   3,3
@@L48    EQU   *
         L     12,0(,10)
         LR    15,3
* Function ropen epilogue
         PDPEPIL
* Function ropen literal pool
         DS    0F
         LTORG
* Function ropen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
