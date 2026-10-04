         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fflush prologue
FFLUSH   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fflush code
         L     4,0(11)
         SLR   2,2
         LR    3,2
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         LA    3,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         LR    2,15
         LTR   3,3
         BE    @@L3
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function fflush epilogue
         PDPEPIL
* Function fflush literal pool
         DS    0F
         LTORG
* Function fflush page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
