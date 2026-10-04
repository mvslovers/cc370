         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ecb_post'
* Program text area
         DS    0F
* X-func *@@ECBPST prologue
@@ECBPST PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ECBPST code
         L     3,0(11)
         L     2,4(11)
         POST  (3),(2)
         SLR   15,15
* Function *@@ECBPST epilogue
         PDPEPIL
* Function *@@ECBPST literal pool
         DS    0F
         LTORG
* Function *@@ECBPST page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
