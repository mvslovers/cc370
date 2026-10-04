         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fgets prologue
@@FGETS  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fgets code
         L     4,0(11)
         L     3,4(11)
         L     5,8(11)
         SLR   15,15
         LH    2,40(5)
         N     2,=F'513'
         LTR   2,2
         BNE   @@L13
         LTR   3,3
         BH    @@L4
@@L13    EQU   *
         L     12,0(,10)
         LR    4,15
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         BCTR  3,0
         LR    2,15
         CR    15,3
         BNL   @@L10
@@L9     EQU   *
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@FGETC)
         BALR  14,15
         L     6,=F'-1'
         CLR   15,6
         BE    @@L6
         STC   15,0(4,2)
         A     2,=F'1'
         LA    6,21(0,0)
         CR    15,6
         BE    @@L6
         CR    2,3
         BL    @@L9
@@L6     EQU   *
         L     12,0(,10)
         LTR   2,2
         BNE   @@L10
         L     3,=F'-1'
         CLR   15,3
         BNE   @@L10
         LR    4,2
         B     @@L3
@@L10    EQU   *
         L     12,0(,10)
         SLR   6,6
         STC   6,0(2,4)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __fgets epilogue
         PDPEPIL
* Function __fgets literal pool
         DS    0F
         LTORG
* Function __fgets page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
