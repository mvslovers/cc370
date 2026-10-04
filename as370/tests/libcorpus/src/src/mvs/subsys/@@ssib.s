         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@SSIB prologue
@@SSIB   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SSIB code
         L     15,PSATOLD-PSA          OUR TCB ADDRESS
         L     15,TCBJSCB-TCB(,15)     JSCB ADDRESS
         USING IEZJSCB,15
         L     15,JSCBACT              ACTIVE JSCB ADDRESS
         L     15,JSCBSSIB             SSIB ADDRESS
         DROP  15
         ST    15,88(13)
         L     15,88(13)
* Function *@@SSIB epilogue
         PDPEPIL
* Function *@@SSIB literal pool
         DS    0F
         LTORG
* Function *@@SSIB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         PRINT NOGEN
         IEZJSCB
         IKJTCB
         IHAPSA
         IEFJSSIB
         END
