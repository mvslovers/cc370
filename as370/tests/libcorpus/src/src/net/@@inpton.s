         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@INPTON prologue
@@INPTON PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@INPTON code
         L     3,4(11)
         SLR   6,6
         LR    7,6
         L     2,0(11)
         LA    4,2(0,0)
         CLR   2,4
         BE    @@L15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'47'
         L     15,=F'-1'
         B     @@L1
@@L15    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L6
         CLI   0(3),75
         BNE   @@L23
         A     3,=F'1'
@@L6     EQU   *
         L     12,0(,10)
         SLR   4,4
         LR    15,4
         IC    5,0(3)
         LA    2,16(,5)
         CLM   2,1,=XL1'09'
         BH    @@L24
@@L13    EQU   *
         LTR   4,4
         BE    @@L11
         LTR   15,15
         BE    @@L1
@@L11    EQU   *
         L     12,0(,10)
         LR    2,15
         SLL   2,3
         AR    2,15
         AR    15,2
         SLR   2,2
         IC    2,0(3)
         AR    15,2
         A     15,=F'-240'
         LA    2,255(0,0)
         CLR   15,2
         BH    @@L23
         A     3,=F'1'
         A     4,=F'1'
         IC    5,0(3)
         LA    2,16(,5)
         CLM   2,1,=XL1'09'
         BNH   @@L13
         LTR   4,4
         BE    @@L24
         SLL   6,8
         OR    6,15
         A     7,=F'1'
         LA    4,3(0,0)
         CR    7,4
         BNH   @@L15
         SLR   15,15
         CLM   5,1,=XL1'00'
         BNE   @@L1
         B     @@L16
@@L23    EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L1
@@L24    EQU   *
         L     12,0(,10)
         LR    15,4
         B     @@L1
@@L16    EQU   *
         L     12,0(,10)
         L     2,8(11)
         ST    6,0(2)
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@INPTON epilogue
         PDPEPIL
* Function *@@INPTON literal pool
         DS    0F
         LTORG
* Function *@@INPTON page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
