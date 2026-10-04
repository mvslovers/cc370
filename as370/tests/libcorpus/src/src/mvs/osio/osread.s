         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osread prologue
OSREAD   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osread code
         L     5,0(11)
         L     4,4(11)
         L     3,8(11)
         L     2,12(11)
         
         READ  (5),SF,(4),(3),(2),MF=E
@@L2     EQU   *
* Function osread epilogue
         PDPEPIL
* Function osread literal pool
         DS    0F
         LTORG
* Function osread page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
