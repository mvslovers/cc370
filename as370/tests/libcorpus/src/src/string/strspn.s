         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strspn prologue
STRSPN   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strspn code
         L     4,0(11)
         L     5,4(11)
         LR    15,4
         IC    2,0(4)
@@L13    EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L11
         LR    3,5
@@L14    EQU   *
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L5
         CLC   0(1,15),0(3)
         BE    @@L5
         A     3,=F'1'
         B     @@L14
@@L5     EQU   *
         L     12,0(,10)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L11
         A     15,=F'1'
         IC    2,0(15)
         B     @@L13
@@L11    EQU   *
         L     12,0(,10)
         SR    15,4
* Function strspn epilogue
         PDPEPIL
* Function strspn literal pool
         DS    0F
         LTORG
* Function strspn page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
