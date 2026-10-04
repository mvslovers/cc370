         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strncasecmp prologue
STRNCASE PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strncasecmp code
         L     7,0(11)
         L     6,4(11)
         L     5,8(11)
         SLR   4,4
@@L12    EQU   *
         CLR   4,5
         BNL   @@L11
         SLR   2,2
         IC    2,0(4,7)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         IC    15,1(2,3)
         SLR   2,2
         IC    2,0(4,6)
         AR    2,2
         IC    2,1(2,3)
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
         A     4,=F'1'
         B     @@L12
@@L11    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strncasecmp epilogue
         PDPEPIL
* Function strncasecmp literal pool
         DS    0F
         LTORG
* Function strncasecmp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
