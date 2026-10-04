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
* X-func vvprintf prologue
VVPRINTF PDPPRLG CINDEX=0,FRAME=240,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vvprintf code
         SLR   2,2
         SLR   3,3
         ST    2,224(13)
         ST    3,4+224(13)
         ST    2,232(13)
         ST    3,4+232(13)
         L     8,12(11)
         SLR   9,9
         ST    9,216(13)
         ST    9,220(13)
         L     3,8(11)
         LTR   3,3
         BE    @@L45
         ST    3,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L45
         MVC   220(4,13),=F'1'
@@L45    EQU   *
         L     12,0(,10)
         L     3,0(11)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L6
         MVC   216(4,13),=F'1'
         B     @@L7
@@L6     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'6C'
         BNE   @@L8
         LR    4,3
         A     4,=F'1'
         ST    4,0(11)
         IC    3,0(4)
         CLM   3,1,=XL1'84'
         BNE   @@L9
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         A     2,=F'-4'
         L     5,0(2)
         LPR   3,5
         LA    4,120(,13)
@@L12    EQU   *
         ST    3,224(13)
         L     6,224(13)
         L     7,4+224(13)
         SRDL  6,32
         LA    2,10(0,0)
         DR    6,2
         ST    6,224(13)
         ST    7,4+224(13)
         LA    2,240(,6)
         STC   2,0(4)
         A     4,=F'1'
         ST    3,232(13)
         L     6,232(13)
         L     7,4+232(13)
         SRDL  6,32
         LA    2,10(0,0)
         DR    6,2
         ST    6,232(13)
         ST    7,4+232(13)
         LR    3,7
         L     6,236(13)
         LTR   6,6
         BNE   @@L12
         LTR   5,5
         BNL   @@L16
         MVI   0(4),96
         A     4,=F'1'
@@L16    EQU   *
         L     12,0(,10)
         BCTR  4,0
         L     7,8(11)
         LTR   7,7
         BNE   @@L19
         MVC   0(1,8),0(4)
         A     8,=F'1'
         B     @@L20
@@L19    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(4)
         ST    2,88(13)
         MVC   92(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@FPUTC)
         BALR  14,15
@@L20    EQU   *
         L     12,0(,10)
         A     9,=F'1'
         LA    2,120(,13)
         CLR   4,2
         BNE   @@L16
         B     @@L7
@@L9     EQU   *
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
         L     2,4(11)
         A     2,=F'8'
         ST    2,4(11)
         A     2,=F'-8'
         MVC   88(8,13),0(2)
         SLR   2,2
         IC    2,0(4)
         ST    2,96(13)
         MVC   100(4,13),=F'0'
         MVC   104(4,13),=F'6'
         LA    7,120(,13)
         ST    7,108(13)
         MVC   112(4,13),=F'96'
         LA    1,88(,13)
         L     15,=V(@@DBLCVT)
         BALR  14,15
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
         L     3,8(11)
         LTR   3,3
         BE    @@L50
         ST    7,88(13)
         MVC   92(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@FPUTS)
         BALR  14,15
         B     @@L49
@@L22    EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'A2'
         BNE   @@L26
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         A     2,=F'-4'
         L     7,0(2)
         LTR   7,7
         BNE   @@L27
         L     7,=A(@@LC1)
@@L27    EQU   *
         L     12,0(,10)
         L     6,8(11)
         LTR   6,6
         BNE   @@L28
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
@@L50    EQU   *
         L     12,0(,10)
         LR    4,8
         LR    5,6
         LR    2,7
         LR    3,6
         MVCL  4,2
         AR    8,6
@@L49    EQU   *
         L     12,0(,10)
         AR    9,6
         B     @@L7
@@L28    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         MVC   92(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@FPUTS)
         BALR  14,15
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         AR    9,15
         B     @@L7
@@L26    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'83'
         BNE   @@L31
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         A     2,=F'-4'
         L     5,0(2)
         L     7,8(11)
         LTR   7,7
         BNE   @@L32
         STC   5,0(8)
         B     @@L52
@@L32    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         B     @@L53
@@L31    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'95'
         BNE   @@L35
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         A     2,=F'-4'
         L     2,0(2)
         ST    9,0(2)
         B     @@L7
@@L35    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'6C'
         BNE   @@L37
         L     3,8(11)
         LTR   3,3
         BE    @@L51
         MVC   88(4,13),=F'108'
         B     @@L53
@@L37    EQU   *
         L     12,0(,10)
         ST    11,88(13)
         MVC   92(4,13),8(11)
         ST    8,96(13)
         LA    2,4(,11)
         ST    2,100(13)
         MVC   104(4,13),=F'2147483647'
         LA    1,88(,13)
         L     15,=V(@@EXAMIN)
         BALR  14,15
         AR    9,15
         LTR   8,8
         BE    @@L7
         AR    8,15
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         L     6,8(11)
         LTR   6,6
         BNE   @@L43
@@L51    EQU   *
         L     12,0(,10)
         STC   2,0(8)
@@L52    EQU   *
         L     12,0(,10)
         A     8,=F'1'
         B     @@L44
@@L43    EQU   *
         L     12,0(,10)
         N     2,=XL4'000000FF'
         ST    2,88(13)
@@L53    EQU   *
         L     12,0(,10)
         MVC   92(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@FPUTC)
         BALR  14,15
@@L44    EQU   *
         L     12,0(,10)
         A     9,=F'1'
@@L7     EQU   *
         L     12,0(,10)
         L     2,0(11)
         A     2,=F'1'
         ST    2,0(11)
         L     7,216(13)
         LTR   7,7
         BE    @@L45
         L     2,220(13)
         LTR   2,2
         BE    @@L46
         MVC   88(4,13),8(11)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L46    EQU   *
         L     12,0(,10)
         LR    15,9
* Function vvprintf epilogue
         PDPEPIL
* Function vvprintf literal pool
         DS    0F
         LTORG
* Function vvprintf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
