         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fgetpos prologue
FGETPOS  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fgetpos code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(FTELL)
         BALR  14,15
         L     2,4(11)
         ST    15,0(2)
         SLR   15,15
* Function fgetpos epilogue
         PDPEPIL
* Function fgetpos literal pool
         DS    0F
         LTORG
* Function fgetpos page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
