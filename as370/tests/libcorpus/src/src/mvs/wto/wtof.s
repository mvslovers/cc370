         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wtof prologue
WTOF     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wtof code
         MVC   88(4,13),0(11)
         LA    2,4(,11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(VWTOF)
         BALR  14,15
* Function wtof epilogue
         PDPEPIL
* Function wtof literal pool
         DS    0F
         LTORG
* Function wtof page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
