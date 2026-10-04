         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fpswt prologue
@@FPSWT  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpswt code
         L     3,0(11)
         L     6,4(11)
         L     4,24(3)
         LH    5,40(3)
         LR    15,5
         N     15,=XL4'0000FFFF'
         LR    2,15
         N     2,=F'16384'
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'9'
         B     @@L28
@@L2     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L3
         CLI   52(3),64
         BH    @@L16
         LR    2,15
         N     2,=F'2048'
         LTR   2,2
         BE    @@L5
         N     15,=F'1'
         LTR   15,15
         BNE   @@L5
@@L6     EQU   *
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BNE   @@L6
         LH    2,40(3)
         N     2,=F'2'
         LR    5,15
         LTR   2,2
         BNE   @@L1
         B     @@L14
@@L5     EQU   *
         L     12,0(,10)
         LR    15,5
         N     15,=XL4'0000FFFF'
         LR    2,15
         N     2,=F'2048'
         LTR   2,2
         BNE   @@L3
         LR    2,15
         N     2,=F'1'
         LTR   2,2
         BNE   @@L3
         LR    4,2
         L     2,20(3)
         L     5,=F'-1'
         CLR   2,5
         BE    @@L12
         LA    4,1(0,0)
@@L12    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         LH    2,40(3)
         N     2,=F'2'
         L     5,=F'-1'
         LTR   2,2
         BNE   @@L1
         CLR   15,5
         BE    @@L14
         LTR   4,4
         BE    @@L15
         ST    15,20(3)
         B     @@L16
@@L15    EQU   *
         L     12,0(,10)
         L     2,32(3)
         BCTR  2,0
         ST    2,32(3)
         L     2,24(3)
         BCTR  2,0
         ST    2,24(3)
@@L16    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'45'
         B     @@L28
@@L14    EQU   *
         L     12,0(,10)
         L     4,24(3)
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         L     5,=F'-1'
         LTR   15,15
         BNE   @@L1
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BNH   @@L18
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     5,0(15)
         LTR   6,6
         BE    @@L19
         ST    4,24(3)
         B     @@L20
@@L19    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
@@L20    EQU   *
         L     12,0(,10)
         LH    2,40(3)
         LR    4,2
         O     4,=F'2'
         STH   4,40(3)
         LA    4,28(0,0)
         CLR   5,4
         BNE   @@L26
         O     2,=F'6'
         STH   2,40(3)
         B     @@L26
@@L18    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L22
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     2,0(15)
         LA    5,5(0,0)
         LTR   2,2
         BE    @@L24
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     5,0(15)
@@L24    EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L25
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BNE   @@L25
         NC    40(2,3),=H'-33'
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
@@L25    EQU   *
         L     12,0(,10)
         LH    15,40(3)
         LR    2,15
         N     2,=F'16384'
         LTR   2,2
         BNE   @@L26
         O     15,=F'2'
         STH   15,40(3)
@@L26    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    5,0(15)
@@L28    EQU   *
         L     12,0(,10)
         L     5,=F'-1'
         B     @@L1
@@L22    EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L27
         ST    4,24(3)
         LR    5,15
         B     @@L1
@@L27    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
         LR    5,6
@@L1     EQU   *
         L     12,0(,10)
         LR    15,5
* Function __fpswt epilogue
         PDPEPIL
* Function __fpswt literal pool
         DS    0F
         LTORG
* Function __fpswt page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'redcb'
         DS    0F
* Function redcb,F2 prologue
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
* Function redcb code
         L     3,0(11)
         SLR   4,4
         LH    2,40(3)
         N     2,=F'16384'
         LTR   2,2
         BE    @@L30
         MVC   88(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         LTR   15,15
         BE    @@L30
         LA    4,28(0,0)
         LA    2,12(0,0)
         CLR   15,2
         BE    @@L30
         LA    4,5(0,0)
@@L30    EQU   *
         L     12,0(,10)
         MVC   8(4,3),=F'0'
         MVC   12(4,3),=F'0'
         L     2,28(3)
         LTR   2,2
         BE    @@L34
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L34    EQU   *
         L     12,0(,10)
         MVC   28(4,3),=F'0'
         MVC   32(4,3),=F'0'
         MVC   36(4,3),=F'0'
         MVC   20(4,3),=F'-1'
         LH    15,40(3)
         N     15,=F'-16402'
         STH   15,40(3)
         L     2,4(11)
         LTR   2,2
         BE    @@L35
         O     15,=F'16'
         STH   15,40(3)
@@L35    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'0'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPOPEN)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BNE   @@L29
         LR    2,4
         LTR   4,4
         BE    @@L29
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    4,0(15)
         LA    2,1(0,0)
@@L29    EQU   *
         L     12,0(,10)
         LR    15,2
* Function redcb epilogue
         PDPEPIL
* Function redcb literal pool
         DS    0F
         LTORG
* Function redcb page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'skipto'
         DS    0F
* Function skipto,F3 prologue
@@F3     PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function skipto code
         L     3,0(11)
         L     4,4(11)
         MVC   24(4,3),=F'0'
         LH    2,40(3)
         N     2,=F'32'
         LTR   2,2
         BE    @@L39
@@L40    EQU   *
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BNE   @@L40
         NC    40(2,3),=H'-33'
         B     @@L38
@@L39    EQU   *
         L     12,0(,10)
         CLR   2,4
         BNL   @@L38
@@L46    EQU   *
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     2,=F'-1'
         CLR   15,2
         BE    @@L38
         L     2,24(3)
         CLR   2,4
         BL    @@L46
@@L38    EQU   *
         L     12,0(,10)
* Function skipto epilogue
         PDPEPIL
* Function skipto literal pool
         DS    0F
         LTORG
* Function skipto page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         DS    0F
* X-func __fpupc prologue
@@FPUPC  PDPPRLG CINDEX=3,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function __fpupc code
         L     4,0(11)
         L     7,4(11)
         LH    3,40(4)
         N     3,=XL4'0000FFFF'
         SRL   3,10
         X     3,=F'1'
         N     3,=F'1'
         MVC   20(4,4),=F'-1'
         L     2,32(4)
         CL    2,36(4)
         BL    @@L49
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         LR    6,15
         LH    2,40(4)
         N     2,=F'2'
         L     5,=F'-1'
         LTR   2,2
         BNE   @@L48
         CLR   15,5
         BNE   @@L51
         ST    4,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=A(@@FPSWT)
         BALR  14,15
         LR    5,6
         LTR   15,15
         BNE   @@L48
         LA    5,1(0,0)
         B     @@L48
@@L51    EQU   *
         L     12,0(,10)
         L     2,32(4)
         BCTR  2,0
         ST    2,32(4)
         L     2,24(4)
         BCTR  2,0
         ST    2,24(4)
@@L49    EQU   *
         L     12,0(,10)
         L     6,36(4)
         LR    5,6
         LTR   3,3
         BE    @@L53
         BCTR  5,0
@@L53    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L54
         L     2,32(4)
         CLR   2,5
         BL    @@L54
         LA    3,21(0,0)
         CLR   7,3
         BNE   @@L60
         A     2,=F'1'
         ST    2,32(4)
         L     2,24(4)
         A     2,=F'1'
         ST    2,24(4)
         B     @@L61
@@L54    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L56
         LA    2,21(0,0)
         CLR   7,2
         BNE   @@L56
         IC    2,42(4)
         N     2,=F'192'
         LA    3,128(0,0)
         CLR   2,3
         BE    @@L57
@@L60    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'45'
         L     5,=F'-1'
         B     @@L48
@@L57    EQU   *
         L     12,0(,10)
         L     2,32(4)
         LA    3,64(0,0)
         SR    5,2
         
*** MEMSET ***
         LR    14,2           => target (s)
         LR    15,5           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LR    3,6
         SR    3,2
         LR    2,3
         A     2,24(4)
         ST    2,24(4)
         ST    6,32(4)
         B     @@L59
@@L56    EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'32'
         L     3,0(2)
         STC   7,0(3)
         A     3,=F'1'
         ST    3,0(2)
         L     2,24(4)
         A     2,=F'1'
         ST    2,24(4)
@@L59    EQU   *
         L     12,0(,10)
         OI    191(4),2
@@L61    EQU   *
         L     12,0(,10)
         SLR   5,5
@@L48    EQU   *
         L     12,0(,10)
         LR    15,5
* Function __fpupc epilogue
         PDPEPIL
* Function __fpupc literal pool
         DS    0F
         LTORG
* Function __fpupc page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         END
