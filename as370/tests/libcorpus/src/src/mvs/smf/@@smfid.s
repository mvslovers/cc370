         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __smfid prologue
@@SMFID  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __smfid code
         LA    1,88(,13)
         L     15,=V(@@SMCA)
         BALR  14,15
         SLR   2,2
         LTR   15,15
         BE    @@L2
         LR    2,15
         A     2,=F'16'
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __smfid epilogue
         PDPEPIL
* Function __smfid literal pool
         DS    0F
         LTORG
* Function __smfid page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
