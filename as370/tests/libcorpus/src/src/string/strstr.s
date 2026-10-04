         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strstr prologue
STRSTR   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strstr code
         L     5,4(11)
         L     15,0(11)
@@L13    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L11
         IC    3,0(15)
         CLM   3,1,0(5)
         BNE   @@L4
         LR    4,15
         LR    2,5
         CLM   3,1,=XL1'00'
         BE    @@L6
@@L7     EQU   *
         A     4,=F'1'
         A     2,=F'1'
         IC    3,0(2)
         CLM   3,1,=XL1'00'
         BE    @@L6
         CLM   3,1,0(4)
         BE    @@L7
@@L6     EQU   *
         L     12,0(,10)
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L1
@@L4     EQU   *
         L     12,0(,10)
         A     15,=F'1'
         B     @@L13
@@L11    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strstr epilogue
         PDPEPIL
* Function strstr literal pool
         DS    0F
         LTORG
* Function strstr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
