         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rwrite prologue
RWRITE   PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rwrite code
         L     7,0(11)
         L     6,4(11)
         MVC   104(4,13),28(7)
         L     5,24(7)
         L     3,16(7)
         L     2,8(11)
         LTR   2,2
         BNE   @@L2
         ST    3,8(11)
@@L2     EQU   *
         L     12,0(,10)
         L     4,12(7)
         LA    2,1(0,0)
         CLR   4,2
         BNE   @@L3
         IC    2,36(5)
         N     2,=F'8'
         LTR   2,2
         BE    @@L3
         A     3,=F'-4'
@@L3     EQU   *
         L     12,0(,10)
         L     15,8(11)
         CLR   15,3
         BH    @@L7
         LA    2,1(0,0)
         CLR   4,2
         BNE   @@L5
         LA    4,3(0,0)
         CLR   15,4
         BNH   @@L7
         SLR   2,2
         IC    2,0(6)
         SLL   2,8
         SLR   3,3
         IC    3,1(6)
         OR    2,3
         CLR   2,15
         BNE   @@L7
         IC    2,2(6)
         CLM   2,1,=XL1'00'
         BNE   @@L7
         IC    2,3(6)
         CLM   2,1,=XL1'00'
         BE    @@L5
@@L7     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         LA    15,1(0,0)
         B     @@L1
@@L5     EQU   *
         L     12,0(,10)
         L     4,104(13)
         LR    5,15
         LR    2,6
         LR    3,15
         MVCL  4,2
         MVC   88(4,13),24(7)
         LA    2,104(,13)
         ST    2,92(13)
         LA    2,8(,11)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@AWRITE)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L8
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    3,28(0,0)
         LA    4,12(0,0)
         CLR   2,4
         BE    @@L10
         LA    3,5(0,0)
@@L10    EQU   *
         L     12,0(,10)
         ST    3,0(15)
         LA    2,1(0,0)
@@L8     EQU   *
         L     12,0(,10)
         LR    15,2
@@L1     EQU   *
         L     12,0(,10)
* Function rwrite epilogue
         PDPEPIL
* Function rwrite literal pool
         DS    0F
         LTORG
* Function rwrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
