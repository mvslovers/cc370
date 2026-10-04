         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mtxfree prologue
MTXFREE  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxfree code
         L     4,0(11)
         L     2,0(4)
         LTR   2,2
         BE    @@L2
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLR   3,3
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L4     EQU   *
* Function mtxfree epilogue
         PDPEPIL
* Function mtxfree literal pool
         DS    0F
         LTORG
* Function mtxfree page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
