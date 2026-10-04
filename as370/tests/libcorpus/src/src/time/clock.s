         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func clock prologue
CLOCK    PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function clock code
         L     15,=F'-1'
* Function clock epilogue
         PDPEPIL
* Function clock literal pool
         DS    0F
         LTORG
* Function clock page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
