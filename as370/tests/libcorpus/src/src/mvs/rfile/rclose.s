         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rclose prologue
RCLOSE   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rclose code
         L     3,0(11)
         SLR   5,5
         LTR   3,3
         BE    @@L3
         L     2,24(3)
         LTR   2,2
         BE    @@L4
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L4
         L     5,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    4,28(0,0)
         LA    6,12(0,0)
         CLR   2,6
         BE    @@L7
         LA    4,5(0,0)
@@L7     EQU   *
         L     12,0(,10)
         ST    4,0(15)
@@L4     EQU   *
         L     12,0(,10)
         L     2,8(3)
         LTR   2,2
         BE    @@L8
         A     3,=F'32'
         ST    3,88(13)
         A     3,=F'-32'
         LA    1,88(,13)
         L     15,=V(@@FDCLR)
         BALR  14,15
         LTR   15,15
         BE    @@L8
         LTR   5,5
         BNE   @@L8
         L     5,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
@@L8     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function rclose epilogue
         PDPEPIL
* Function rclose literal pool
         DS    0F
         LTORG
* Function rclose page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
