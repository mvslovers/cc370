         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strxfrm prologue
STRXFRM  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strxfrm code
         L     7,0(11)
         L     6,4(11)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         CL    15,8(11)
         BNL   @@L2
         LR    4,7
         LR    5,15
         LR    2,6
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,0(15,7)
@@L2     EQU   *
         L     12,0(,10)
* Function strxfrm epilogue
         PDPEPIL
* Function strxfrm literal pool
         DS    0F
         LTORG
* Function strxfrm page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
