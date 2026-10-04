         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_add'
* Program text area
         DS    0F
* X-func *@@64ADD prologue
@@64ADD  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64ADD code
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
         LA    4,3(0,0)
@@L7     EQU   *
         LR    3,4
         AR    3,4
         LH    15,0(3,8)
         N     15,=XL4'0000FFFF'
         LH    2,0(3,7)
         N     2,=XL4'0000FFFF'
         AR    15,2
         AR    15,5
         SLR   5,5
         L     2,=F'65535'
         CLR   15,2
         BNH   @@L6
         LA    5,1(0,0)
@@L6     EQU   *
         L     12,0(,10)
         STH   15,0(3,6)
         BCTR  4,0
         LTR   4,4
         BNL   @@L7
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64ADD epilogue
         PDPEPIL
* Function *@@64ADD literal pool
         DS    0F
         LTORG
* Function *@@64ADD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
