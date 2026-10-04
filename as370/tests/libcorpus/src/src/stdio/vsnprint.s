         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'eEgGfF'
         DC    X'0'
@@LC1    EQU   *
         DC    C'(null)'
         DC    X'0'
         DS    0F
* X-func vsnprintf prologue
VSNPRINT PDPPRLG CINDEX=0,FRAME=240,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vsnprintf code
         SLR   2,2
         SLR   3,3
         ST    2,224(13)
         ST    3,4+224(13)
         ST    2,232(13)
         ST    3,4+232(13)
         L     5,0(11)
         SLR   6,6
         ST    6,216(13)
         LR    7,6
         L     3,4(11)
         LTR   3,3
         BE    @@L54
         LR    7,3
         BCTR  7,0
         LTR   7,7
         BNL   @@L54
         L     7,=F'2147483647'
@@L54    EQU   *
         L     12,0(,10)
         L     3,8(11)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L7
         MVC   216(4,13),=F'1'
         B     @@L8
@@L7     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'6C'
         BNE   @@L9
         LR    4,3
         A     4,=F'1'
         ST    4,8(11)
         IC    3,0(4)
         CLM   3,1,=XL1'84'
         BNE   @@L10
         L     2,12(11)
         A     2,=F'4'
         ST    2,12(11)
         A     2,=F'-4'
         L     4,0(2)
         LPR   15,4
         LA    3,120(,13)
@@L13    EQU   *
         ST    15,224(13)
         L     8,224(13)
         L     9,4+224(13)
         SRDL  8,32
         LA    2,10(0,0)
         DR    8,2
         ST    8,224(13)
         ST    9,4+224(13)
         LA    2,240(,8)
         STC   2,0(3)
         A     3,=F'1'
         ST    15,232(13)
         L     8,232(13)
         L     9,4+232(13)
         SRDL  8,32
         LA    2,10(0,0)
         DR    8,2
         ST    8,232(13)
         ST    9,4+232(13)
         LR    15,9
         L     8,236(13)
         LTR   8,8
         BNE   @@L13
         LTR   4,4
         BNL   @@L17
         MVI   0(3),96
         A     3,=F'1'
@@L17    EQU   *
         L     12,0(,10)
         BCTR  3,0
         CR    6,7
         BNL   @@L20
         MVC   0(1,5),0(3)
         A     5,=F'1'
@@L20    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         LA    9,120(,13)
         CLR   3,9
         BNE   @@L17
         B     @@L8
@@L10    EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=XL4'000000FF'
         MVC   88(4,13),=A(@@LC0)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L22
         CLM   3,1,=XL1'00'
         BE    @@L22
         L     2,12(11)
         A     2,=F'8'
         ST    2,12(11)
         A     2,=F'-8'
         MVC   88(8,13),0(2)
         SLR   2,2
         IC    2,0(4)
         ST    2,96(13)
         MVC   100(4,13),=F'0'
         MVC   104(4,13),=F'6'
         LA    3,120(,13)
         ST    3,108(13)
         MVC   112(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(@@DBLCVT)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         SLR   2,2
@@L64    EQU   *
         CR    2,15
         BNL   @@L8
         CR    6,7
         BNL   @@L26
         MVC   0(1,5),0(3)
         A     5,=F'1'
@@L26    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     2,=F'1'
         A     3,=F'1'
         B     @@L64
@@L22    EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'A2'
         BNE   @@L29
         L     2,12(11)
         A     2,=F'4'
         ST    2,12(11)
         A     2,=F'-4'
         L     3,0(2)
         LTR   3,3
         BNE   @@L30
         L     3,=A(@@LC1)
@@L30    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         SLR   2,2
@@L65    EQU   *
         CR    2,15
         BNL   @@L8
         CR    6,7
         BNL   @@L34
         IC    4,0(2,3)
         STC   4,0(5)
         A     5,=F'1'
@@L34    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     2,=F'1'
         B     @@L65
@@L29    EQU   *
         L     12,0(,10)
         SLL   2,24
         SRA   2,24
         C     2,=F'-125'
         BNE   @@L37
         L     2,12(11)
         A     2,=F'4'
         ST    2,12(11)
         A     2,=F'-4'
         L     4,0(2)
         CR    6,7
         BNL   @@L53
         STC   4,0(5)
         B     @@L67
@@L37    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'95'
         BNE   @@L40
         L     2,12(11)
         A     2,=F'4'
         ST    2,12(11)
         A     2,=F'-4'
         L     2,0(2)
         ST    6,0(2)
         B     @@L8
@@L40    EQU   *
         L     12,0(,10)
         SLL   2,24
         SRA   2,24
         C     2,=F'108'
         BE    @@L9
         LR    15,7
         SR    15,6
         BNL   @@L45
         SLR   15,15
@@L45    EQU   *
         L     12,0(,10)
         LA    2,8(,11)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         ST    5,96(13)
         LA    2,12(,11)
         ST    2,100(13)
         ST    15,104(13)
         LA    1,88(,13)
         L     15,=V(@@EXAMIN)
         BALR  14,15
         LTR   5,5
         BE    @@L46
         SLR   2,2
@@L66    EQU   *
         CR    2,15
         BNL   @@L8
         CR    6,7
         BNL   @@L50
         A     5,=F'1'
@@L50    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     2,=F'1'
         B     @@L66
@@L46    EQU   *
         L     12,0(,10)
         AR    6,15
         B     @@L8
@@L9     EQU   *
         L     12,0(,10)
         CR    6,7
         BNL   @@L53
         STC   2,0(5)
@@L67    EQU   *
         L     12,0(,10)
         A     5,=F'1'
@@L53    EQU   *
         L     12,0(,10)
         A     6,=F'1'
@@L8     EQU   *
         L     12,0(,10)
         L     2,8(11)
         A     2,=F'1'
         ST    2,8(11)
         L     8,216(13)
         LTR   8,8
         BE    @@L54
         L     9,4(11)
         LTR   9,9
         BE    @@L55
         MVI   0(5),0
@@L55    EQU   *
         L     12,0(,10)
         LR    15,6
* Function vsnprintf epilogue
         PDPEPIL
* Function vsnprintf literal pool
         DS    0F
         LTORG
* Function vsnprintf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
