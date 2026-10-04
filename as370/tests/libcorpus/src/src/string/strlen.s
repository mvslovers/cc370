         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strlen prologue
STRLEN   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strlen code
         L     3,0(11)
         LR    15,3
         IC    2,0(3)
@@L7     EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L6
         A     15,=F'1'
         IC    2,0(15)
         B     @@L7
@@L6     EQU   *
         L     12,0(,10)
         SR    15,3
* Function strlen epilogue
         PDPEPIL
* Function strlen literal pool
         DS    0F
         LTORG
* Function strlen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
