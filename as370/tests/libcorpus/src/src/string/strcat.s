         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strcat prologue
STRCAT   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strcat code
         L     15,0(11)
         L     4,4(11)
         LR    3,15
         IC    2,0(15)
@@L12    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L9
         A     3,=F'1'
         IC    2,0(3)
         B     @@L12
@@L9     EQU   *
         L     12,0(,10)
         IC    2,0(4)
         STC   2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L11
@@L7     EQU   *
         A     3,=F'1'
         A     4,=F'1'
         IC    2,0(4)
         STC   2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L7
@@L11    EQU   *
         L     12,0(,10)
* Function strcat epilogue
         PDPEPIL
* Function strcat literal pool
         DS    0F
         LTORG
* Function strcat page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
