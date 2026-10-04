         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memcmp prologue
MEMCMP   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memcmp code
         L     6,0(11)
         L     5,4(11)
         L     4,8(11)
         SLR   3,3
@@L10    EQU   *
         CLR   3,4
         BNL   @@L9
         IC    2,0(3,6)
         IC    15,0(3,5)
         STC   15,80(,13)
         CLM   2,1,80(13)
         BNL   @@L4
         L     15,=F'-1'
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         STC   15,80(,13)
         CLM   2,1,80(13)
         BNH   @@L5
         LA    15,1(0,0)
         B     @@L1
@@L5     EQU   *
         L     12,0(,10)
         A     3,=F'1'
         B     @@L10
@@L9     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function memcmp epilogue
         PDPEPIL
* Function memcmp literal pool
         DS    0F
         LTORG
* Function memcmp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
