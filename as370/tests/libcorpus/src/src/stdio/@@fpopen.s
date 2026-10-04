         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__fpopen'
* Program text area
         DS    0F
* X-func __fpopen prologue
@@FPOPEN PDPPRLG CINDEX=0,FRAME=352,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpopen code
         L     7,0(11)
         MVC   332(4,13),=F'1'
         SLR   6,6
         ST    6,312(13)
         ST    6,316(13)
         ST    6,320(13)
         ST    6,324(13)
         ST    6,328(13)
         ST    6,336(13)
         MVC   296(8,13),=XL8'0000000000000000'
         MVC   304(8,13),=XL8'0000000000000000'
         LA    4,120(,13)
         LA    5,176(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LTR   7,7
         BE    @@L3
         IC    2,43(7)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L3
         LR    3,7
         A     3,=F'43'
@@L8     EQU   *
         LA    4,296(,13)
         IC    2,0(3)
         STC   2,0(4,6)
         A     6,=F'1'
         A     3,=F'1'
         LA    8,7(0,0)
         CR    6,8
         BH    @@L6
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L8
@@L6     EQU   *
         L     12,0(,10)
         LA    2,7(0,0)
         CR    6,2
         BH    @@L59
@@L12    EQU   *
         LA    3,64(0,0)
         STC   3,0(4,6)
         A     6,=F'1'
         LA    8,7(0,0)
         CR    6,8
         BNH   @@L12
@@L59    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@DDBUSY)
         BALR  14,15
         LTR   15,15
         BE    @@L13
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'16'
         B     @@L3
@@L13    EQU   *
         L     12,0(,10)
         LH    4,40(7)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'16'
         LTR   2,2
         BE    @@L14
         N     3,=F'2056'
         LA    2,3(0,0)
         LTR   3,3
         BNE   @@L16
         LA    2,1(0,0)
@@L16    EQU   *
         L     12,0(,10)
         ST    2,312(13)
         B     @@L17
@@L14    EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BE    @@L17
         N     3,=F'2048'
         LTR   3,3
         BNE   @@L17
         CLI   52(7),64
         BH    @@L17
         MVC   312(4,13),=F'2'
@@L17    EQU   *
         L     12,0(,10)
         NI    191(7),252
         LR    2,4
         N     2,=F'256'
         LTR   2,2
         BE    @@L19
         L     2,312(13)
         A     2,=F'8'
         ST    2,312(13)
@@L19    EQU   *
         L     12,0(,10)
         IC    2,52(7)
         CLM   2,1,=XL1'40'
         BNH   @@L20
         SLR   6,6
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L28
         LR    3,7
         A     3,=F'52'
@@L24    EQU   *
         IC    2,0(3)
         STC   2,304(6,13)
         A     6,=F'1'
         A     3,=F'1'
         LA    4,7(0,0)
         CR    6,4
         BH    @@L22
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L24
@@L22    EQU   *
         L     12,0(,10)
         LA    8,7(0,0)
         CR    6,8
         BH    @@L62
@@L28    EQU   *
         L     12,0(,10)
         LA    2,64(0,0)
         STC   2,304(6,13)
         A     6,=F'1'
         LA    3,7(0,0)
         CR    6,3
         BNH   @@L28
@@L62    EQU   *
         L     12,0(,10)
         LA    4,304(,13)
         ST    4,336(13)
@@L20    EQU   *
         L     12,0(,10)
         IC    2,42(7)
         N     2,=F'192'
         LA    8,128(0,0)
         CR    2,8
         BE    @@L30
         BH    @@L33
         LA    3,64(0,0)
         CLR   2,3
         BE    @@L31
         B     @@L29
@@L33    EQU   *
         L     12,0(,10)
         LA    4,192(0,0)
         CLR   2,4
         BE    @@L32
         B     @@L29
@@L30    EQU   *
         L     12,0(,10)
         MVC   316(4,13),=F'0'
         B     @@L29
@@L31    EQU   *
         L     12,0(,10)
         MVC   316(4,13),=F'1'
         B     @@L29
@@L32    EQU   *
         L     12,0(,10)
         MVC   316(4,13),=F'2'
@@L29    EQU   *
         L     12,0(,10)
         LH    2,16(7)
         N     2,=XL4'0000FFFF'
         ST    2,320(13)
         LH    2,18(7)
         N     2,=XL4'0000FFFF'
         ST    2,324(13)
         L     3,312(13)
         LA    8,296(,13)
         ST    8,88(13)
         LA    2,312(,13)
         ST    2,92(13)
         LA    9,316(,13)
         ST    9,96(13)
         LA    8,320(,13)
         ST    8,100(13)
         LA    5,324(,13)
         ST    5,104(13)
         LA    4,328(,13)
         ST    4,108(13)
         MVC   112(4,13),336(13)
         LA    1,88(,13)
         L     15,=V(@@AOPEN)
         BALR  14,15
         ST    15,8(7)
         LR    2,3
         N     2,=F'7'
         LA    4,2(0,0)
         CR    2,4
         BNE   @@L34
         LTR   15,15
         BNL   @@L35
         A     3,=F'-2'
         ST    3,312(13)
         LA    2,296(,13)
         ST    2,88(13)
         LA    3,312(,13)
         ST    3,92(13)
         ST    9,96(13)
         ST    8,100(13)
         ST    5,104(13)
         LA    4,328(,13)
         ST    4,108(13)
         MVC   112(4,13),336(13)
         LA    1,88(,13)
         L     15,=V(@@AOPEN)
         BALR  14,15
         ST    15,8(7)
         B     @@L34
@@L35    EQU   *
         L     12,0(,10)
         OI    191(7),1
@@L34    EQU   *
         L     12,0(,10)
         L     3,8(7)
         LTR   3,3
         BNL   @@L37
         L     8,=F'-45'
         CLR   3,8
         BNE   @@L3
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'45'
         B     @@L3
@@L37    EQU   *
         L     12,0(,10)
         LH    5,40(7)
         O     5,=F'16384'
         STH   5,40(7)
         MVC   12(4,7),328(13)
         MVC   20(4,7),=F'-1'
         LR    4,5
         N     4,=XL4'0000FFFF'
         LR    2,4
         N     2,=F'8192'
         LTR   2,2
         BE    @@L39
         LR    2,4
         N     2,=F'4096'
         LTR   2,2
         BE    @@L39
         IC    2,17(3)
         N     2,=F'240'
         LA    8,32(0,0)
         CLR   2,8
         BE    @@L40
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         MVC   8(4,7),=F'0'
         MVC   12(4,7),=F'0'
         NC    40(2,7),=H'-16385'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         MVC   332(4,13),=F'1'
         B     @@L3
@@L40    EQU   *
         L     12,0(,10)
         N     4,=F'16'
         LTR   4,4
         BE    @@L39
         O     5,=F'8'
         STH   5,40(7)
@@L39    EQU   *
         L     12,0(,10)
         MVC   42(1,7),36(3)
         MVC   16(2,7),82(3)
         MVC   18(2,7),62(3)
         LH    2,40(7)
         N     2,=F'512'
         LTR   2,2
         BNE   @@L42
         IC    2,42(7)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L44
         BH    @@L47
         LA    4,64(0,0)
         CLR   2,4
         BE    @@L45
         B     @@L43
@@L47    EQU   *
         L     12,0(,10)
         LA    8,192(0,0)
         CLR   2,8
         BE    @@L46
         B     @@L43
@@L44    EQU   *
         L     12,0(,10)
         LH    6,16(7)
         B     @@L64
@@L45    EQU   *
         L     12,0(,10)
         LH    6,16(7)
         N     6,=XL4'0000FFFF'
         A     6,=F'-4'
         B     @@L43
@@L46    EQU   *
         L     12,0(,10)
         LH    6,18(7)
@@L64    EQU   *
         L     12,0(,10)
         N     6,=XL4'0000FFFF'
@@L43    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         A     6,=F'8'
         ST    6,92(13)
         A     6,=F'-8'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,28(7)
         LTR   15,15
         BE    @@L3
         LH    2,40(7)
         N     2,=F'16'
         LTR   2,2
         BE    @@L49
         ST    15,32(7)
         AR    6,15
         ST    6,36(7)
         B     @@L42
@@L49    EQU   *
         L     12,0(,10)
         ST    15,32(7)
         ST    15,36(7)
@@L42    EQU   *
         L     12,0(,10)
         MVC   88(4,13),8(7)
         LA    2,120(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@RDJFCB)
         BALR  14,15
         ST    15,332(13)
         LTR   15,15
         BNE   @@L3
         CLI   120(13),64
         BNH   @@L3
         LR    6,15
         CLI   0(2),64
         BNH   @@L54
         LR    3,2
         LR    2,7
         A     2,=F'61'
@@L56    EQU   *
         MVC   0(1,2),0(3)
         A     6,=F'1'
         A     2,=F'1'
         A     3,=F'1'
         LA    4,43(0,0)
         CR    6,4
         BH    @@L54
         CLI   0(3),64
         BH    @@L56
@@L54    EQU   *
         L     12,0(,10)
         SLR   8,8
         STC   8,61(7,6)
@@L3     EQU   *
         L     12,0(,10)
         L     15,332(13)
* Function __fpopen epilogue
         PDPEPIL
* Function __fpopen literal pool
         DS    0F
         LTORG
* Function __fpopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
