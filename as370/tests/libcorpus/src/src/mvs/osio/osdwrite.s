         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osdwrite prologue
OSDWRITE PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osdwrite code
         L     6,0(11)
         L     4,4(11)
         L     5,8(11)
         L     2,12(11)
         LA    3,16(,11)
         LTR   2,2
         BNH   @@L2
         STH   2,62(4)
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LH    2,62(4)
         N     2,=XL4'0000FFFF'
@@L3     EQU   *
         L     12,0(,10)
         A     3,=F'1'
         
         WRITE (6),DI,(4),(5),(2),0,(3),MF=E
         LR    2,15
@@L4     EQU   *
         LR    15,2
* Function osdwrite epilogue
         PDPEPIL
* Function osdwrite literal pool
         DS    0F
         LTORG
* Function osdwrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
