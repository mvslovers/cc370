         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func setvbuf prologue
SETVBUF  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function setvbuf code
         SLR   15,15
* Function setvbuf epilogue
         PDPEPIL
* Function setvbuf literal pool
         DS    0F
         LTORG
* Function setvbuf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
