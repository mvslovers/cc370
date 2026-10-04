         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fread prologue
@@FREAD  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fread code
         SLR   4,4
         SLR   5,5
         L     7,4(11)
         L     8,12(11)
         L     9,0(11)
         MVC   108(4,13),=F'0'
         L     6,8(11)
         LH    3,40(8)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'9'
         LR    6,2
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LR    15,3
         N     15,=F'2'
         LTR   15,15
         BNE   @@L25
         LR    2,3
         N     2,=F'1'
         LTR   2,2
         BE    @@L5
         LR    6,15
         B     @@L3
@@L5     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'512'
         LTR   2,2
         BE    @@L6
         LR    5,7
         MR    4,6
         LR    7,5
         MVC   88(4,13),8(8)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,108(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AREAD)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         LH    2,40(8)
         BNH   @@L8
         O     2,=F'2'
         STH   2,40(8)
@@L25    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         O     2,=F'1'
         STH   2,40(8)
@@L9     EQU   *
         L     12,0(,10)
         SLR   6,6
         B     @@L3
@@L7     EQU   *
         L     12,0(,10)
         L     2,108(13)
         CLR   5,2
         BNH   @@L10
         LR    7,2
@@L10    EQU   *
         L     12,0(,10)
         LR    4,9
         LR    5,7
         L     2,104(13)
         LR    3,7
         MVCL  4,2
         L     2,24(8)
         A     2,=F'1'
         ST    2,24(8)
         B     @@L3
@@L6     EQU   *
         L     12,0(,10)
         LR    6,2
@@L23    EQU   *
         CL    6,8(11)
         BNL   @@L3
         SLR   2,2
@@L24    EQU   *
         CLR   2,7
         BNL   @@L22
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     3,=F'-1'
         CLR   15,3
         BE    @@L3
         STC   15,0(9)
         A     9,=F'1'
         A     2,=F'1'
         B     @@L24
@@L22    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L23
@@L3     EQU   *
         L     12,0(,10)
         LR    15,6
* Function __fread epilogue
         PDPEPIL
* Function __fread literal pool
         DS    0F
         LTORG
* Function __fread page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
