         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fwrite prologue
@@FWRITE PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fwrite code
         SLR   4,4
         SLR   5,5
         LR    8,4
         LR    9,5
         L     6,4(11)
         L     7,0(11)
         MVC   112(4,13),=F'0'
         L     2,12(11)
         LH    3,40(2)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'9'
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BE    @@L4
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     3,12(11)
         LH    2,40(3)
         N     2,=F'4'
         LA    3,28(0,0)
         LTR   2,2
         BNE   @@L20
         B     @@L34
@@L4     EQU   *
         L     12,0(,10)
         N     3,=F'512'
         LTR   3,3
         BE    @@L7
         L     7,12(11)
         LH    15,16(7)
         N     15,=XL4'0000FFFF'
         LTR   6,6
         BE    @@L3
         L     2,8(11)
         LTR   2,2
         BE    @@L3
         MVC   135(1,13),42(7)
         SLR   3,3
         IC    3,135(13)
         LR    7,3
         N     7,=F'192'
         LA    2,64(0,0)
         CLR   7,2
         BNE   @@L10
         N     3,=F'8'
         LTR   3,3
         BE    @@L10
         A     15,=F'-4'
@@L10    EQU   *
         L     12,0(,10)
         LR    4,15
         SLR   5,5
         CLR   6,15
         BH    @@L14
         LTR   6,6
         BL    @@L13
         LA    3,1(0,0)
         CLR   6,3
         BE    @@L12
         SRDL  4,32
         DR    4,6
         B     @@L14
@@L12    EQU   *
         L     12,0(,10)
         LR    5,15
         B     @@L14
@@L13    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L14    EQU   *
         L     12,0(,10)
         L     7,8(11)
         CLR   7,5
         BH    @@L16
         LR    9,6
         L     2,8(11)
         MR    8,2
         LR    6,9
         IC    2,135(13)
         N     2,=F'192'
         LA    3,64(0,0)
         CLR   2,3
         BNE   @@L15
         LA    4,3(0,0)
         CLR   9,4
         BNH   @@L16
         L     5,0(11)
         SLR   2,2
         IC    2,0(5)
         SLL   2,8
         SLR   3,3
         IC    3,1(5)
         OR    2,3
         CLR   2,9
         BNE   @@L16
         IC    2,2(5)
         CLM   2,1,=XL1'00'
         BNE   @@L16
         IC    2,3(5)
         CLM   2,1,=XL1'00'
         BE    @@L15
@@L16    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         B     @@L3
@@L15    EQU   *
         L     12,0(,10)
         ST    6,108(13)
         L     7,12(11)
         L     2,12(7)
         ST    2,104(13)
         LR    4,2
         LR    5,6
         L     2,0(11)
         LR    3,6
         MVCL  4,2
         MVC   88(4,13),8(7)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AWRITE)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L17
         LH    3,40(7)
         LR    4,3
         O     4,=F'2'
         STH   4,40(7)
         LA    5,12(0,0)
         CLR   15,5
         BNE   @@L18
         O     3,=F'6'
         STH   3,40(7)
@@L18    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    3,28(0,0)
         LA    7,12(0,0)
         CLR   2,7
         BE    @@L20
@@L34    EQU   *
         L     12,0(,10)
         LA    3,5(0,0)
@@L20    EQU   *
         L     12,0(,10)
         ST    3,0(15)
         B     @@L3
@@L17    EQU   *
         L     12,0(,10)
         L     3,12(11)
         L     2,24(3)
         A     2,=F'1'
         ST    2,24(3)
         MVC   112(4,13),=F'1'
         B     @@L3
@@L7     EQU   *
         L     12,0(,10)
         L     4,112(13)
         CL    4,8(11)
         BNL   @@L3
@@L29    EQU   *
         SLR   3,3
@@L33    EQU   *
         CLR   3,6
         BNL   @@L32
         SLR   2,2
         IC    2,0(7)
         ST    2,88(13)
         A     7,=F'1'
         MVC   92(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(@@FPUTC)
         BALR  14,15
         L     5,=F'-1'
         CLR   15,5
         BE    @@L3
         A     3,=F'1'
         B     @@L33
@@L32    EQU   *
         L     12,0(,10)
         L     2,112(13)
         A     2,=F'1'
         ST    2,112(13)
         CL    2,8(11)
         BL    @@L29
@@L3     EQU   *
         L     12,0(,10)
         L     15,112(13)
* Function __fwrite epilogue
         PDPEPIL
* Function __fwrite literal pool
         DS    0F
         LTORG
* Function __fwrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
