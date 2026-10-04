         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fputc prologue
@@FPUTC  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fputc code
         L     6,0(11)
         L     4,4(11)
         LR    5,6
         LH    3,40(4)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'4096'
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'9'
         B     @@L19
@@L2     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=F'512'
         LTR   2,2
         BNE   @@L3
         LR    2,3
         N     2,=F'2'
         LTR   2,2
         BE    @@L5
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LH    2,40(4)
         N     2,=F'4'
         LA    3,28(0,0)
         LTR   2,2
         BNE   @@L7
         LA    3,5(0,0)
@@L7     EQU   *
         L     12,0(,10)
         ST    3,0(15)
         B     @@L19
@@L5     EQU   *
         L     12,0(,10)
         N     3,=F'16'
         LTR   3,3
         BNE   @@L8
         IC    2,191(4)
         N     2,=F'1'
         LTR   2,2
         BE    @@L9
         ST    4,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPUPC)
         BALR  14,15
         LTR   15,15
         BL    @@L19
         BNE   @@L8
         B     @@L3
@@L9     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@FPSWT)
         BALR  14,15
         LTR   15,15
         BNE   @@L19
@@L8     EQU   *
         L     12,0(,10)
         LH    2,40(4)
         N     2,=F'1024'
         LTR   2,2
         BNE   @@L14
         LA    2,21(0,0)
         CLR   6,2
         BNE   @@L14
         L     2,24(4)
         A     2,=F'1'
         ST    2,24(4)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLNL)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         B     @@L19
@@L14    EQU   *
         L     12,0(,10)
         L     2,32(4)
         CL    2,36(4)
         BNE   @@L17
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         LTR   15,15
         BE    @@L17
@@L19    EQU   *
         L     12,0(,10)
         L     5,=F'-1'
         B     @@L3
@@L17    EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'32'
         L     3,0(2)
         STC   6,0(3)
         A     3,=F'1'
         ST    3,0(2)
         L     2,24(4)
         A     2,=F'1'
         ST    2,24(4)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function __fputc epilogue
         PDPEPIL
* Function __fputc literal pool
         DS    0F
         LTORG
* Function __fputc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
