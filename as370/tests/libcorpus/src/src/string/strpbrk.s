         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strpbrk prologue
STRPBRK  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strpbrk code
         L     4,4(11)
         L     15,0(11)
@@L13    EQU   *
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L10
         LR    3,4
@@L14    EQU   *
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L12
         CLC   0(1,15),0(3)
         BE    @@L1
         A     3,=F'1'
         B     @@L14
@@L12    EQU   *
         L     12,0(,10)
         A     15,=F'1'
         B     @@L13
@@L10    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strpbrk epilogue
         PDPEPIL
* Function strpbrk literal pool
         DS    0F
         LTORG
* Function strpbrk page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
