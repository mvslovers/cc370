         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wctomb prologue
WCTOMB   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wctomb code
         L     2,0(11)
         L     3,4(11)
         LR    15,2
         LTR   2,2
         BE    @@L1
         L     15,=F'-1'
         LA    4,255(0,0)
         CLR   3,4
         BH    @@L1
         STC   3,0(2)
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function wctomb epilogue
         PDPEPIL
* Function wctomb literal pool
         DS    0F
         LTORG
* Function wctomb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
