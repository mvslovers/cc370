         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_rshift'
* Program text area
         DS    0F
* X-func *@@64RSFT prologue
@@64RSFT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64RSFT code
         L     3,0(11)
         L     7,4(11)
         L     6,8(11)
         LR    2,6
         LTR   6,6
         BNL   @@L2
         A     2,=F'15'
@@L2     EQU   *
         L     12,0(,10)
         SRA   2,4
         LTR   3,3
         BE    @@L1
         LTR   7,7
         BE    @@L1
         LTR   6,6
         BL    @@L1
         ST    3,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         LTR   2,2
         BE    @@L4
         ST    7,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64RSHW)
         BALR  14,15
         SLL   2,4
         SR    6,2
@@L4     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L1
         LA    15,3(0,0)
@@L9     EQU   *
         LR    3,15
         AR    3,15
         LH    5,0(3,7)
         N     5,=XL4'0000FFFF'
         SRA   5,0(6)
         AR    3,7
         A     3,=F'-2'
         LH    4,0(3)
         N     4,=XL4'0000FFFF'
         A     3,=F'2'
         LA    2,16(0,0)
         SR    2,6
         SLL   4,0(2)
         OR    5,4
         STH   5,0(3)
         BCTR  15,0
         LTR   15,15
         BH    @@L9
         LH    2,0(7)
         N     2,=XL4'0000FFFF'
         SRA   2,0(6)
         STH   2,0(7)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64RSFT epilogue
         PDPEPIL
* Function *@@64RSFT literal pool
         DS    0F
         LTORG
* Function *@@64RSFT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
