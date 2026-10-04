         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strncmp prologue
STRNCMP  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strncmp code
         L     6,0(11)
         L     5,4(11)
         L     4,8(11)
         SLR   3,3
@@L12    EQU   *
         CLR   3,4
         BNL   @@L11
         IC    15,0(3,6)
         IC    2,0(3,5)
         STC   2,80(,13)
         CLM   15,1,80(13)
         BNL   @@L4
         L     15,=F'-1'
         B     @@L1
@@L4     EQU   *
         L     12,0(,10)
         STC   2,80(,13)
         CLM   15,1,80(13)
         BNH   @@L6
         LA    15,1(0,0)
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         CLM   15,1,=XL1'00'
         BE    @@L11
         A     3,=F'1'
         B     @@L12
@@L11    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strncmp epilogue
         PDPEPIL
* Function strncmp literal pool
         DS    0F
         LTORG
* Function strncmp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
