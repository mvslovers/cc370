         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __reopen prologue
@@REOPEN PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __reopen code
         L     4,8(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    8,15
         SLR   7,7
         LR    3,7
         LTR   4,4
         BE    @@L3
         LH    2,40(4)
         N     2,=F'16384'
         LTR   2,2
         BE    @@L3
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     2,0(15)
         LA    7,5(0,0)
         LTR   2,2
         BE    @@L5
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     7,0(15)
@@L5     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    5,15
         LH    2,40(4)
         LTR   15,15
         BNE   @@L9
         O     2,=F'2'
         STH   2,40(4)
         LR    4,15
         B     @@L3
@@L9     EQU   *
         L     12,0(,10)
         N     2,=F'16384'
         LTR   2,2
         BE    @@L10
         MVC   88(4,13),8(4)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         LTR   7,7
         BNE   @@L10
         LA    7,28(0,0)
         LA    2,12(0,0)
         CLR   15,2
         BE    @@L10
         LA    7,5(0,0)
@@L10    EQU   *
         L     12,0(,10)
         MVC   8(4,4),8(5)
         MVC   8(4,5),=F'0'
         MVC   12(4,4),12(5)
         MVC   12(4,5),=F'0'
         MVC   16(2,4),16(5)
         MVC   18(2,4),18(5)
         MVC   24(4,4),24(5)
         L     2,28(4)
         LTR   2,2
         BE    @@L14
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         MVC   28(4,4),28(5)
         MVC   28(4,5),=F'0'
         MVC   32(4,4),32(5)
         MVC   32(4,5),=F'0'
         MVC   36(4,4),36(5)
         MVC   36(4,5),=F'0'
         LH    2,40(4)
         CH    2,=H'0'
         BNL   @@L15
         A     4,=F'43'
         A     5,=F'43'
         ST    4,88(13)
         A     4,=F'-43'
         ST    5,92(13)
         A     5,=F'-43'
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LTR   15,15
         BE    @@L16
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FPFREE)
         BALR  14,15
         B     @@L15
@@L25    EQU   *
         ST    6,88(13)
         A     15,=F'1'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L20
@@L16    EQU   *
         L     12,0(,10)
         LA    3,1(0,0)
@@L15    EQU   *
         L     12,0(,10)
         MVC   40(2,4),40(5)
         LTR   3,3
         BE    @@L18
         OC    40(2,4),=H'-32768'
@@L18    EQU   *
         L     12,0(,10)
         MVC   40(2,5),=H'0'
         MVC   42(1,4),42(5)
         MVC   43(9,4),43(5)
         MVC   52(9,4),52(5)
         MVC   61(45,4),61(5)
         MVC   106(85,4),106(5)
         LR    6,8
         A     6,=F'24'
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
@@L26    EQU   *
         LTR   15,15
         BE    @@L20
         BCTR  15,0
         L     2,24(8)
         LR    3,15
         SLL   3,2
         L     2,0(3,2)
         CLR   2,5
         BE    @@L25
         B     @@L26
@@L20    EQU   *
         L     12,0(,10)
         A     8,=F'24'
         ST    8,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LTR   7,7
         BE    @@L3
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    7,0(15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __reopen epilogue
         PDPEPIL
* Function __reopen literal pool
         DS    0F
         LTORG
* Function __reopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
