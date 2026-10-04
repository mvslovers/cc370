         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func llabs prologue
LLABS    PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function llabs code
         LR    4,0
         L     2,0(11)
         L     3,4+0(11)
         LTR   2,2
         BNL   @@L2
         ST    2,88(13)
         ST    3,4+88(13)
         LA    0,96(,13)
         LA    1,88(,13)
         L     15,=V(@@NEGDI2)
         BALR  14,15
         L     2,96(13)
         L     3,4+96(13)
@@L2     EQU   *
         L     12,0(,10)
         ST    2,0(4)
         ST    3,4+0(4)
         LR    15,4
* Function llabs epilogue
         PDPEPIL
* Function llabs literal pool
         DS    0F
         LTORG
* Function llabs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
