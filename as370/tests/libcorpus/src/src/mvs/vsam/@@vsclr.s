         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsclr prologue
@@VSCLR  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsclr code
         L     2,0(11)
         NI    17(2),252
         MVI   18(2),0
         MVI   20(2),0
         MVI   19(2),0
         SLR   15,15
* Function __vsclr epilogue
         PDPEPIL
* Function __vsclr literal pool
         DS    0F
         LTORG
* Function __vsclr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
