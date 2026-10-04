         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@TIOT prologue
@@TIOT   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TIOT code
         L     15,PSATOLD-PSA  OUR TCB ADDRESS
         L     15,TCBTIO-TCB(,15) TIOT ADDRESS
         ST    15,88(13)
         L     15,88(13)
* Function *@@TIOT epilogue
         PDPEPIL
* Function *@@TIOT literal pool
         DS    0F
         LTORG
* Function *@@TIOT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         PRINT NOGEN
         IKJTCB
         IHAPSA
         PRINT GEN
         END
