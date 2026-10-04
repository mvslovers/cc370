         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __ytd prologue
@@YTD    PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __ytd code
         SLR   2,2
         SLR   3,3
         LR    4,2
         LR    5,3
         L     7,0(11)
         LR    15,7
         MH    15,=H'365'
         LR    6,7
         SRL   6,2
         AR    15,6
         LR    2,7
         SRDL  2,32
         LA    6,100(0,0)
         DR    2,6
         SR    15,3
         LR    4,7
         SRDL  4,32
         LA    2,400(0,0)
         DR    4,2
         AR    15,5
* Function __ytd epilogue
         PDPEPIL
* Function __ytd literal pool
         DS    0F
         LTORG
* Function __ytd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
