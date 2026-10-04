         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __findenv prologue
@@FINDEN PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __findenv code
         L     9,0(11)
         L     6,4(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    4,15
         L     8,=F'-1'
         LTR   9,9
         BE    @@L2
         LTR   15,15
         BE    @@L2
         L     2,32(15)
         LTR   2,2
         BE    @@L2
         A     4,=F'32'
         ST    4,88(13)
         A     4,=F'-32'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    7,15
         SLR   5,5
@@L18    EQU   *
         CLR   5,7
         BNL   @@L2
         L     3,32(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BNE   @@L6
         LTR   8,8
         BNL   @@L5
         LR    8,5
         B     @@L5
@@L6     EQU   *
         L     12,0(,10)
         L     2,0(3)
         LTR   2,2
         BE    @@L5
         L     15,8(11)
         LTR   15,15
         BE    @@L9
         ST    2,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(STRCASEC)
         BALR  14,15
         B     @@L21
@@L9     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
@@L21    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L5
         LTR   6,6
         BE    @@L14
         ST    5,0(6)
@@L14    EQU   *
         L     12,0(,10)
         L     15,4(3)
         B     @@L1
@@L5     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         B     @@L18
@@L2     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L16
         ST    8,0(6)
@@L16    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function __findenv epilogue
         PDPEPIL
* Function __findenv literal pool
         DS    0F
         LTORG
* Function __findenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
