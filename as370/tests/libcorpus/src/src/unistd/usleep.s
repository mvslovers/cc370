         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func usleep prologue
USLEEP   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function usleep code
         SLR   2,2
         SLR   3,3
         L     2,0(11)
         SRDL  2,32
         LA    4,26(0,0)
         DR    2,4
         ST    3,88(13)
         LTR   3,3
         BNE   @@L2
         MVC   88(4,13),=F'1'
@@L2     EQU   *
         STIMER WAIT,TUINTVL=88(13)
         L     12,0(,10)
         SLR   15,15
* Function usleep epilogue
         PDPEPIL
* Function usleep literal pool
         DS    0F
         LTORG
* Function usleep page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
