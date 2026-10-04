         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __ddbusy prologue
@@DDBUSY PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __ddbusy code
         L     5,0(11)
         SLR   6,6
         LR    4,6
         LTR   5,5
         BE    @@L1
         IC    2,43(5)
         CLM   2,1,=XL1'00'
         BE    @@L1
         LH    3,40(5)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BE    @@L1
         N     3,=F'4096'
         LTR   3,3
         BNE   @@L1
         ST    6,88(13)
         A     5,=F'43'
         ST    5,92(13)
         A     5,=F'-43'
         LA    1,88(,13)
         L     15,=V(@@GTDSAB)
         BALR  14,15
         LTR   15,15
         BE    @@L1
         L     15,16(15)
         LTR   15,15
         BE    @@L1
         IC    2,3(15)
         N     2,=F'6'
         LTR   2,2
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L1
         L     2,24(15)
         LTR   2,2
         BE    @@L1
         B     @@L10
@@L24    EQU   *
         LA    6,1(0,0)
         B     @@L13
@@L10    EQU   *
         L     12,0(,10)
         ST    6,96(13)
         LR    8,15
         A     8,=F'24'
         ST    8,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L11
         MVC   96(4,13),=F'1'
@@L11    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    9,6
         CLR   6,15
         BNL   @@L13
@@L21    EQU   *
         L     3,24(7)
         LR    2,9
         SLL   2,2
         L     4,0(2,3)
         LTR   4,4
         BE    @@L14
         CLR   4,5
         BE    @@L14
         L     2,8(4)
         LTR   2,2
         BE    @@L14
         LH    3,40(4)
         N     3,=XL4'0000FFFF'
         LR    2,3
         N     2,=F'8192'
         LTR   2,2
         BE    @@L14
         N     3,=F'4096'
         LTR   3,3
         BNE   @@L14
         CLC   43(9,4),43(5)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L24
@@L14    EQU   *
         L     12,0(,10)
         A     9,=F'1'
         CLR   9,15
         BL    @@L21
@@L13    EQU   *
         L     12,0(,10)
         L     2,96(13)
         LTR   2,2
         BE    @@L22
         ST    8,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L22    EQU   *
         L     12,0(,10)
         LR    4,6
@@L1     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __ddbusy epilogue
         PDPEPIL
* Function __ddbusy literal pool
         DS    0F
         LTORG
* Function __ddbusy page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
