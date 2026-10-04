         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rdjfcb prologue
RDJFCB   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rdjfcb code
         L     5,0(11)
         L     3,4(11)
         MVC   92(4,13),=F'-1'
         LR    2,3
         N     2,=F'16777215'
         O     2,=F'-2030043136'
         ST    2,88(13)
         MVC   96(4,13),=F'-2147483648'
         LTR   5,5
         BE    @@L3
         LTR   3,3
         BE    @@L3
         L     4,36(5)
         LR    3,4
         N     3,=F'-16777216'
         LA    2,88(,13)
         OR    3,2
         ST    3,36(5)
         LA    2,96(,13)
         RDJFCB ((5)),MF=(E,(2))
         ST     15,92(13)
         ST    4,36(5)
@@L3     EQU   *
         L     12,0(,10)
         L     15,92(13)
* Function rdjfcb epilogue
         PDPEPIL
* Function rdjfcb literal pool
         DS    0F
         LTORG
* Function rdjfcb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
