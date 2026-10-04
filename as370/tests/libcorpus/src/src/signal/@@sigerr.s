         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __sigerr prologue
@@SIGERR PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __sigerr code
* Function __sigerr epilogue
         PDPEPIL
* Function __sigerr literal pool
         DS    0F
         LTORG
* Function __sigerr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
