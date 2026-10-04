         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strchr prologue
STRCHR   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strchr code
         L     15,0(11)
         L     3,4(11)
@@L10    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L8
         CLM   3,1,0(15)
         BE    @@L1
         A     15,=F'1'
         B     @@L10
@@L8     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L1
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strchr epilogue
         PDPEPIL
* Function strchr literal pool
         DS    0F
         LTORG
* Function strchr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
