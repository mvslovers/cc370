         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func printf prologue
PRINTF   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function printf code
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         MVC   88(4,13),0(15)
         MVC   92(4,13),0(11)
         LA    2,4(,11)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(VFPRINTF)
         BALR  14,15
* Function printf epilogue
         PDPEPIL
* Function printf literal pool
         DS    0F
         LTORG
* Function printf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
