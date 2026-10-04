         COPY  PDPTOP
         CSECT
         DS    0F
@V1      EQU   *
         DS    XL4
* Program text area
         DS    0F
* X-func __errno prologue
@@ERRNO  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __errno code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         A     2,=F'272'
         LTR   15,15
         BNE   @@L3
         L     2,=A(@V1)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __errno epilogue
         PDPEPIL
* Function __errno literal pool
         DS    0F
         LTORG
* Function __errno page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
