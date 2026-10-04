         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func time prologue
TIME     PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function time code
         L     3,0(11)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@GETCLK)
         BALR  14,15
         LTR   3,3
         BE    @@L2
         ST    15,0(3)
@@L2     EQU   *
         L     12,0(,10)
* Function time epilogue
         PDPEPIL
* Function time literal pool
         DS    0F
         LTORG
* Function time page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
