         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_inc'
* Program text area
         DS    0F
* X-func *@@64INC prologue
@@64INC  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64INC code
         L     5,0(11)
         LTR   5,5
         BE    @@L1
         LA    15,3(0,0)
@@L7     EQU   *
         LR    4,15
         AR    4,15
         LH    3,0(4,5)
         N     3,=XL4'0000FFFF'
         A     3,=F'1'
         LR    2,3
         SLL   2,16
         SRA   2,16
         BCTR  3,0
         STH   2,0(4,5)
         N     2,=XL4'0000FFFF'
         CLR   2,3
         BH    @@L1
         BCTR  15,0
         LTR   15,15
         BNL   @@L7
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64INC epilogue
         PDPEPIL
* Function *@@64INC literal pool
         DS    0F
         LTORG
* Function *@@64INC page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
