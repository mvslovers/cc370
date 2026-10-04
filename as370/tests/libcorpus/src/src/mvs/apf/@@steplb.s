         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__steplb'
* Program text area
         DS    0F
* X-func *@@STEPLB prologue
@@STEPLB PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@STEPLB code
         
         ICM   1,15,PSATOLD-PSA(0) Get our TCB address
         ICM   1,15,TCBJLB-TCB(1)  Get STEPLIB DCB
         LA    1,0(,1)             Purify DCB address
         LR    15,1                Save STEPLIB DCB address
* Function *@@STEPLB epilogue
         PDPEPIL
* Function *@@STEPLB literal pool
         DS    0F
         LTORG
* Function *@@STEPLB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         PRINT NOGEN
         IHAPSA ,            MAP LOW STORAGE
         CVT DSECT=YES
         IKJTCB DSECT=YES
         DCBD DSORG=PO,DEVD=DA
         IEZDEB
         PRINT GEN
         CSECT
         END
