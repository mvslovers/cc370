         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func raise prologue
RAISE    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function raise code
         L     3,0(11)
         LR    2,3
         BCTR  2,0
         LA    4,5(0,0)
         CLR   2,4
         BH    @@L2
         LA    1,88(,13)
         L     15,=V(@@SIGHDL)
         BALR  14,15
         ST    3,88(13)
         SLL   3,2
         L     2,0(3,15)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function raise epilogue
         PDPEPIL
* Function raise literal pool
         DS    0F
         LTORG
* Function raise page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
