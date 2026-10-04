         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __mtd prologue
@@MTD    PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __mtd code
         SLR   2,2
         SLR   3,3
         L     4,0(11)
         MH    4,=H'3057'
         LR    2,4
         A     2,=F'-3007'
         SRDL  2,32
         LA    4,100(0,0)
         DR    2,4
         LR    15,3
* Function __mtd epilogue
         PDPEPIL
* Function __mtd literal pool
         DS    0F
         LTORG
* Function __mtd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
