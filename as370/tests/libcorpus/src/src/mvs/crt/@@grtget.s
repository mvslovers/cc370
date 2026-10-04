         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __grtget prologue
@@GRTGET PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __grtget code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L3
         L     2,280(15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __grtget epilogue
         PDPEPIL
* Function __grtget literal pool
         DS    0F
         LTORG
* Function __grtget page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
