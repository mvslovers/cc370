         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func total3 prologue
TOTAL3   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function total3 code
         MVC   88(4,13),=F'3'
         MVC   92(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(ADDUP)
         BALR  14,15
* Function total3 epilogue
         PDPEPIL
* Function total3 literal pool
         DS    0F
         LTORG
* Function total3 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
