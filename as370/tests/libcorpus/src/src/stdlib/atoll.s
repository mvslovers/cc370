         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func atoll prologue
ATOLL    PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function atoll code
         LR    2,0
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'10'
         LA    1,88(,13)
         L     15,=V(STRTOLL)
         BALR  14,15
         LR    15,2
* Function atoll epilogue
         PDPEPIL
* Function atoll literal pool
         DS    0F
         LTORG
* Function atoll page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
