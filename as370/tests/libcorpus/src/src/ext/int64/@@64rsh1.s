         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_rshift_one_bit'
* Program text area
         DS    0F
* X-func *@@64RSH1 prologue
@@64RSH1 PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64RSH1 code
         L     5,0(11)
         LTR   5,5
         BE    @@L1
         LA    15,3(0,0)
@@L6     EQU   *
         LR    2,15
         AR    2,15
         LH    4,0(2,5)
         N     4,=XL4'0000FFFF'
         SRL   4,1
         AR    2,5
         A     2,=F'-2'
         LH    3,0(2)
         N     3,=XL4'0000FFFF'
         A     2,=F'2'
         SLL   3,15
         SLL   3,16
         SRA   3,16
         OR    4,3
         STH   4,0(2)
         BCTR  15,0
         LTR   15,15
         BH    @@L6
         LH    2,0(5)
         N     2,=XL4'0000FFFF'
         SRL   2,1
         STH   2,0(5)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64RSH1 epilogue
         PDPEPIL
* Function *@@64RSH1 literal pool
         DS    0F
         LTORG
* Function *@@64RSH1 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
