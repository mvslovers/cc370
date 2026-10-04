         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strtoumax prologue
STRTOUMA PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtoumax code
         LR    2,0
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(STRTOULL)
         BALR  14,15
         MVC   0(8,2),104(13)
         LR    15,2
* Function strtoumax epilogue
         PDPEPIL
* Function strtoumax literal pool
         DS    0F
         LTORG
* Function strtoumax page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
