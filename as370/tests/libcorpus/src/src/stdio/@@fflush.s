         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fflush prologue
@@FFLUSH PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fflush code
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
* Function __fflush epilogue
         PDPEPIL
* Function __fflush literal pool
         DS    0F
         LTORG
* Function __fflush page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func __fflnl prologue
@@FFLNL  PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __fflnl code
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
* Function __fflnl epilogue
         PDPEPIL
* Function __fflnl literal pool
         DS    0F
         LTORG
* Function __fflnl page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'flushrec'
         DS    0F
* Function flushrec,F2 prologue
@@F2     PDPPRLG CINDEX=2,FRAME=128,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function flushrec code
         L     6,0(11)
         L     8,4(11)
         L     15,8(6)
         SLR   7,7
         IC    5,191(6)
         LR    2,5
         N     2,=F'2'
         LH    4,40(6)
         LTR   2,2
         BE    @@L4
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BE    @@L5
         N     5,=F'-3'
         STC   5,191(6)
         N     3,=F'4'
         LTR   3,3
         BE    @@L6
         LA    7,12(0,0)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'28'
         B     @@L8
@@L6     EQU   *
         L     12,0(,10)
         LA    7,8(0,0)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
         B     @@L8
@@L5     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
         LR    7,15
         B     @@L8
@@L4     EQU   *
         L     12,0(,10)
         LR    3,4
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'512'
         LTR   2,2
         BNE   @@L8
         LR    2,3
         N     2,=F'16'
         LTR   2,2
         BE    @@L8
         L     2,32(6)
         CL    2,28(6)
         BNE   @@L11
         LTR   8,8
         BE    @@L8
@@L11    EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BE    @@L12
         N     3,=F'4'
         LTR   3,3
         BE    @@L13
         LA    7,12(0,0)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'28'
         B     @@L15
@@L13    EQU   *
         L     12,0(,10)
         LA    7,8(0,0)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
         B     @@L15
@@L12    EQU   *
         L     12,0(,10)
         CLI   17(15),79
         BNE   @@L16
         LA    4,96(,13)
         LA    5,32(0,0)
         LR    2,7
         LR    3,7
         MVCL  4,2
         L     2,28(6)
         L     3,32(6)
         SR    3,2
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=A(@@F4)
         BALR  14,15
         LR    7,15
         B     @@L15
@@L16    EQU   *
         L     12,0(,10)
         IC    2,42(6)
         N     2,=F'192'
         LA    3,128(0,0)
         CR    2,3
         BE    @@L19
         BH    @@L23
         LA    5,64(0,0)
         CLR   2,5
         BE    @@L22
         B     @@L17
@@L23    EQU   *
         L     12,0(,10)
         LA    3,192(0,0)
         CLR   2,3
         BNE   @@L17
@@L19    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'1024'
         BCTR  2,0
         SRL   2,25
         ST    6,88(13)
         N     2,=F'64'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F5)
         BALR  14,15
         B     @@L36
@@L22    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
@@L36    EQU   *
         L     12,0(,10)
         LR    7,15
@@L17    EQU   *
         L     12,0(,10)
         LH    4,40(6)
         LTR   7,7
         BE    @@L24
         LR    5,4
         O     5,=F'2'
         STH   5,40(6)
         LA    2,12(0,0)
         CLR   7,2
         BNE   @@L25
         O     4,=F'6'
         STH   4,40(6)
@@L25    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    2,28(0,0)
         LA    3,12(0,0)
         CLR   7,3
         BE    @@L27
         LA    2,5(0,0)
@@L27    EQU   *
         L     12,0(,10)
         ST    2,0(15)
         B     @@L15
@@L24    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L15
         L     3,32(6)
         S     3,28(6)
         LR    4,7
         IC    2,42(6)
         N     2,=F'192'
         LA    5,128(0,0)
         CLR   2,5
         BE    @@L31
         LA    5,192(0,0)
         CLR   2,5
         BE    @@L33
         B     @@L30
@@L31    EQU   *
         L     12,0(,10)
         LH    2,16(6)
         N     2,=XL4'0000FFFF'
         CLR   3,2
         BNL   @@L30
         LR    4,2
         SR    4,3
         B     @@L30
@@L33    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L30
         LA    4,1(0,0)
@@L30    EQU   *
         L     12,0(,10)
         L     2,24(6)
         AR    2,4
         LTR   8,8
         BNE   @@L35
         A     2,=F'1'
@@L35    EQU   *
         L     12,0(,10)
         ST    2,24(6)
@@L15    EQU   *
         L     12,0(,10)
         MVC   32(4,6),28(6)
@@L8     EQU   *
         L     12,0(,10)
         LR    15,7
* Function flushrec epilogue
         PDPEPIL
* Function flushrec literal pool
         DS    0F
         LTORG
* Function flushrec page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC 'updrec'
         DS    0F
* Function updrec,F3 prologue
@@F3     PDPPRLG CINDEX=3,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function updrec code
         L     9,0(11)
         MVC   104(4,13),12(9)
         L     7,28(9)
         L     8,36(9)
         SR    8,7
         NI    191(9),253
         LH    3,40(9)
         LR    2,3
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L38
         LTR   8,8
         BE    @@L38
         BCTR  8,0
@@L38    EQU   *
         L     12,0(,10)
         IC    2,42(9)
         N     2,=F'192'
         LA    4,64(0,0)
         CLR   2,4
         BE    @@L44
         L     6,104(13)
         LA    4,128(0,0)
         CLR   2,4
         BNE   @@L45
         LR    2,3
         N     2,=F'1024'
         BCTR  2,0
         SRL   2,31
         SLL   2,6
         LH    3,16(9)
         N     3,=XL4'0000FFFF'
         
*** MEMSET ***
         LR    14,6           => target (s)
         LR    15,3           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,2            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LR    4,6
         LR    5,8
         LR    2,7
         LR    3,8
         MVCL  4,2
         LH    2,16(9)
         N     2,=XL4'0000FFFF'
         ST    2,108(13)
         B     @@L39
@@L44    EQU   *
         L     12,0(,10)
         LR    4,8
         A     4,=F'4'
         LR    3,4
         SRL   3,8
         L     2,104(13)
         STC   3,0(2)
         LA    3,4(,8)
         L     2,104(13)
         STC   3,1(2)
         L     2,104(13)
         MVI   2(2),0
         L     2,104(13)
         MVI   3(2),0
         L     6,104(13)
         A     6,=F'4'
         LR    7,8
         L     2,28(9)
         LR    3,8
         MVCL  6,2
         ST    4,108(13)
         B     @@L39
@@L45    EQU   *
         L     12,0(,10)
         LR    4,6
         LR    5,8
         LR    2,7
         LR    3,8
         MVCL  4,2
         ST    8,108(13)
@@L39    EQU   *
         L     12,0(,10)
         MVC   88(4,13),8(9)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AWRITE)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L46
         LH    3,40(9)
         LR    4,3
         O     4,=F'2'
         STH   4,40(9)
         LA    4,12(0,0)
         CLR   15,4
         BNE   @@L47
         O     3,=F'6'
         STH   3,40(9)
@@L47    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    3,28(0,0)
         LA    4,12(0,0)
         CLR   2,4
         BE    @@L49
         LA    3,5(0,0)
@@L49    EQU   *
         L     12,0(,10)
         ST    3,0(15)
@@L46    EQU   *
         L     12,0(,10)
         LR    15,2
* Function updrec epilogue
         PDPEPIL
* Function updrec literal pool
         DS    0F
         LTORG
* Function updrec page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC 'fixflush'
         DS    0F
* Function fixflush,F5 prologue
@@F5     PDPPRLG CINDEX=4,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function fixflush code
         L     7,0(11)
         L     4,4(11)
         L     8,28(7)
         L     6,32(7)
         SR    6,8
         IC    2,42(7)
         N     2,=F'192'
         LA    3,192(0,0)
         CLR   2,3
         BNE   @@L51
         L     2,12(7)
         LTR   6,6
         BNE   @@L52
         MVC   108(4,13),=F'1'
         ST    2,104(13)
         STC   4,0(2)
         B     @@L54
@@L52    EQU   *
         L     12,0(,10)
         ST    6,108(13)
         ST    2,104(13)
         B     @@L57
@@L51    EQU   *
         L     12,0(,10)
         LH    3,16(7)
         N     3,=XL4'0000FFFF'
         ST    3,108(13)
         L     2,12(7)
         ST    2,104(13)
         
*** MEMSET ***
         LR    14,2           => target (s)
         LR    15,3           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,4            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L57    EQU   *
         L     12,0(,10)
         LR    4,2
         LR    5,6
         LR    2,8
         LR    3,6
         MVCL  4,2
@@L54    EQU   *
         L     12,0(,10)
         MVC   88(4,13),8(7)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AWRITE)
         BALR  14,15
@@L56    EQU   *
* Function fixflush epilogue
         PDPEPIL
* Function fixflush literal pool
         DS    0F
         LTORG
* Function fixflush page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         
&FUNC    SETC 'varflush'
         DS    0F
* Function varflush,F6 prologue
@@F6     PDPPRLG CINDEX=5,FRAME=120,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function varflush code
         L     5,0(11)
         SLR   7,7
         L     6,28(5)
         L     3,32(5)
         SR    3,6
         LR    4,3
         A     4,=F'4'
         ST    4,108(13)
         L     2,12(5)
         ST    2,104(13)
         A     2,=F'4'
         ST    2,112(13)
         ST    3,116(13)
         LR    8,6
         LR    9,3
         L     2,112(13)
         L     3,4+112(13)
         MVCL  2,8
         LR    3,4
         SRL   3,8
         L     2,104(13)
         STC   3,0(2)
         L     2,104(13)
         STC   4,1(2)
         L     2,104(13)
         STC   7,2(2)
         L     2,104(13)
         STC   7,3(2)
         MVC   88(4,13),8(5)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AWRITE)
         BALR  14,15
@@L59    EQU   *
* Function varflush epilogue
         PDPEPIL
* Function varflush literal pool
         DS    0F
         LTORG
* Function varflush page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         DS    0F
* Function tso_putline,F4 prologue
@@F4     PDPPRLG CINDEX=6,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN6
         LTORG
@@FEN6   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG6    EQU   *
         LR    11,1
         L     10,=A(@@PGT6)
* Function tso_putline code
         L     2,0(11)
         L     15,4(11)
         LTR   15,15
         BE    @@L62
         N     15,=F'65535'
         N     2,=F'16777215'
         O     2,=F'134217728'
         LR    0,15                buffer length
         LR    1,2                flags and buffer address
         TPUT  (1),(0),R
@@L62    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function tso_putline epilogue
         PDPEPIL
* Function tso_putline literal pool
         DS    0F
         LTORG
* Function tso_putline page table
         DS    0F
@@PGT6   EQU   *
         DC    A(@@PG6)
         END
