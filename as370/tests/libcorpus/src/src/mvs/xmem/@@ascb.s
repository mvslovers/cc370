         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'ASCB'
         DC    X'0'
         DS    0F
* X-func __ascb prologue
@@ASCB   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __ascb code
         L     3,0(11)
         SLR   4,4
         L     2,16(4)
         L     2,556(2)
         LR    15,4
         LTR   3,3
         BNE   @@L2
         L     15,548(4)
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         CL    3,516(2)
         BNL   @@L3
         SLL   3,2
         L     15,524(2,3)
         N     15,=F'2147483647'
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         CLC   0(4,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
         LR    15,4
@@L3     EQU   *
         L     12,0(,10)
* Function __ascb epilogue
         PDPEPIL
* Function __ascb literal pool
         DS    0F
         LTORG
* Function __ascb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
