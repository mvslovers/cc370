         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strcmp prologue
STRCMP   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strcmp code
         L     15,0(11)
         L     4,4(11)
@@L14    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L11
         IC    3,0(15)
         IC    2,0(4)
         STC   2,80(,13)
         CLM   3,1,80(13)
         BL    @@L8
         BH    @@L13
         A     15,=F'1'
         A     4,=F'1'
         B     @@L14
@@L11    EQU   *
         L     12,0(,10)
         IC    2,0(4)
         SLR   15,15
         CLM   2,1,=XL1'00'
         BE    @@L1
         B     @@L8
@@L13    EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
         B     @@L1
@@L8     EQU   *
         L     12,0(,10)
         L     15,=F'-1'
@@L1     EQU   *
         L     12,0(,10)
* Function strcmp epilogue
         PDPEPIL
* Function strcmp literal pool
         DS    0F
         LTORG
* Function strcmp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
