         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func log10 prologue
LOG10    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function log10 code
         MVC   88(8,13),0(11)
         LA    1,88(,13)
         L     15,=V(LOG)
         BALR  14,15
         DD    0,=D'2.30258509299404567904901E+0'
* Function log10 epilogue
         PDPEPIL
* Function log10 literal pool
         DS    0F
         LTORG
* Function log10 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
