         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_lshift'
* Program text area
         DS    0F
* X-func *@@64LSFT prologue
@@64LSFT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64LSFT code
         L     3,0(11)
         L     7,4(11)
         L     5,8(11)
         LTR   3,3
         BE    @@L1
         LTR   7,7
         BE    @@L1
         LTR   5,5
         BL    @@L1
         LR    2,5
         SRA   2,4
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
         L     15,=V(@@64LSHW)
         BALR  14,15
         SLL   2,4
         SR    5,2
@@L4     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L1
         LR    15,7
         LA    6,2(0,0)
@@L9     EQU   *
         LH    4,0(15)
         N     4,=XL4'0000FFFF'
         SLL   4,0(5)
         LH    3,2(15)
         N     3,=XL4'0000FFFF'
         LA    2,16(0,0)
         SR    2,5
         SRA   3,0(2)
         OR    4,3
         STH   4,0(15)
         BCTR  6,0
         A     15,=F'2'
         LTR   6,6
         BNL   @@L9
         LH    2,6(7)
         N     2,=XL4'0000FFFF'
         SLL   2,0(5)
         STH   2,6(7)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64LSFT epilogue
         PDPEPIL
* Function *@@64LSFT literal pool
         DS    0F
         LTORG
* Function *@@64LSFT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
