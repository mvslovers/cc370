         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strncat prologue
STRNCAT  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strncat code
         L     15,0(11)
         L     4,4(11)
         L     6,8(11)
         LR    3,15
         SLR   5,5
         IC    2,0(15)
@@L11    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L13
         A     3,=F'1'
         IC    2,0(3)
         B     @@L11
@@L12    EQU   *
         CLR   5,6
         BNL   @@L6
         STC   2,0(3)
         A     3,=F'1'
         A     4,=F'1'
         A     5,=F'1'
@@L13    EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L12
@@L6     EQU   *
         L     12,0(,10)
         MVI   0(3),0
* Function strncat epilogue
         PDPEPIL
* Function strncat literal pool
         DS    0F
         LTORG
* Function strncat page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
