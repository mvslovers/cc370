         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ecb_wait'
* Program text area
         DS    0F
* X-func *@@ECBWT prologue
@@ECBWT  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ECBWT code
         L     2,0(11)
         WAIT  ECB=(2)
         SLR   15,15
* Function *@@ECBWT epilogue
         PDPEPIL
* Function *@@ECBWT literal pool
         DS    0F
         LTORG
* Function *@@ECBWT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
