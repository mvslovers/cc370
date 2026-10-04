         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func signal prologue
SIGNAL   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function signal code
         L     3,0(11)
         L     4,4(11)
         LR    2,3
         BCTR  2,0
         LA    5,5(0,0)
         CLR   2,5
         BH    @@L2
         LA    1,88(,13)
         L     15,=V(@@SIGHDL)
         BALR  14,15
         SLL   3,2
         ST    4,0(3,15)
@@L2     EQU   *
         L     12,0(,10)
         LR    15,4
* Function signal epilogue
         PDPEPIL
* Function signal literal pool
         DS    0F
         LTORG
* Function signal page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
