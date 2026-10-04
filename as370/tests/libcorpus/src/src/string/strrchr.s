         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strrchr prologue
STRRCHR  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strrchr code
         L     2,0(11)
         L     3,4(11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         AR    15,2
@@L8     EQU   *
         CLR   15,2
         BL    @@L7
         CLM   3,1,0(15)
         BE    @@L1
         BCTR  15,0
         B     @@L8
@@L7     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strrchr epilogue
         PDPEPIL
* Function strrchr literal pool
         DS    0F
         LTORG
* Function strrchr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
