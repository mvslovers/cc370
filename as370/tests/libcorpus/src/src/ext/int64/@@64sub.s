         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_sub'
* Program text area
         DS    0F
* X-func *@@64SUB prologue
@@64SUB  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64SUB code
         L     8,0(11)
         L     7,4(11)
         L     6,8(11)
         SLR   5,5
         LTR   8,8
         BE    @@L1
         LTR   7,7
         BE    @@L1
         LTR   6,6
         BE    @@L1
         LA    15,3(0,0)
@@L7     EQU   *
         LR    4,15
         AR    4,15
         LH    3,0(4,8)
         N     3,=XL4'0000FFFF'
         A     3,=F'65536'
         LH    2,0(4,7)
         N     2,=XL4'0000FFFF'
         AR    2,5
         SR    3,2
         STH   3,0(4,6)
         SLR   5,5
         L     2,=F'65535'
         CLR   3,2
         BH    @@L5
         LA    5,1(0,0)
@@L5     EQU   *
         L     12,0(,10)
         BCTR  15,0
         LTR   15,15
         BNL   @@L7
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64SUB epilogue
         PDPEPIL
* Function *@@64SUB literal pool
         DS    0F
         LTORG
* Function *@@64SUB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
