         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mtxnew prologue
MTXNEW   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxnew code
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'8'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L2
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(MTXINIT)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
* Function mtxnew epilogue
         PDPEPIL
* Function mtxnew literal pool
         DS    0F
         LTORG
* Function mtxnew page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
