         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __frtx9a prologue
@@FRTX9A PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __frtx9a code
         L     5,0(11)
         LTR   5,5
         BE    @@L1
         L     2,0(5)
         LTR   2,2
         BE    @@L1
         ST    2,96(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
         SLR   3,3
@@L9     EQU   *
         CLR   3,4
         BNL   @@L8
         LR    2,3
         SLL   2,2
         A     2,96(13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX99)
         BALR  14,15
         A     3,=F'1'
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function __frtx9a epilogue
         PDPEPIL
* Function __frtx9a literal pool
         DS    0F
         LTORG
* Function __frtx9a page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
