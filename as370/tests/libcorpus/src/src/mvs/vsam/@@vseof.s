         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vseof prologue
@@VSEOF  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vseof code
         L     2,0(11)
         IC    2,17(2)
         N     2,=F'1'
         LA    15,1(0,0)
         LTR   2,2
         BNE   @@L1
         LR    15,2
@@L1     EQU   *
         L     12,0(,10)
* Function __vseof epilogue
         PDPEPIL
* Function __vseof literal pool
         DS    0F
         LTORG
* Function __vseof page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
