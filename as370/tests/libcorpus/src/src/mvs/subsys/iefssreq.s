         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func iefssreq prologue
IEFSSREQ PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function iefssreq code
         SLR   2,2
         L     2,16(2)
         L     2,296(2)
         L     3,20(2)
         L     2,0(11)
         A     2,=F'-2147483648'
         MODESET MODE=SUP
         ST    2,88(13)
         LA    1,88(,13)
         LA    15,0(3)
         BALR  14,15
         LR    2,15
         MODESET MODE=PROB
         LR    15,2
* Function iefssreq epilogue
         PDPEPIL
* Function iefssreq literal pool
         DS    0F
         LTORG
* Function iefssreq page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
