         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func oswrite prologue
OSWRITE  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function oswrite code
         L     5,0(11)
         L     3,4(11)
         L     4,8(11)
         L     2,12(11)
         LTR   2,2
         BNH   @@L2
         STH   2,62(3)
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LH    2,62(3)
         N     2,=XL4'0000FFFF'
@@L3     EQU   *
         
         WRITE (5),SF,(3),(4),(2),MF=E
         LR    2,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function oswrite epilogue
         PDPEPIL
* Function oswrite literal pool
         DS    0F
         LTORG
* Function oswrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
