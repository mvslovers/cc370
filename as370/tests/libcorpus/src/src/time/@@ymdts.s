         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __ymdts prologue
@@YMDTS  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __ymdts code
         L     4,0(11)
         L     2,4(11)
         L     3,8(11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@MTD)
         BALR  14,15
         AR    3,15
         LA    5,2(0,0)
         CLR   2,5
         BNH   @@L2
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ISLEAP)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         BCTR  3,0
         B     @@L2
@@L3     EQU   *
         L     12,0(,10)
         A     3,=F'-2'
@@L2     EQU   *
         L     12,0(,10)
         BCTR  4,0
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@YTD)
         BALR  14,15
         AR    15,3
* Function __ymdts epilogue
         PDPEPIL
* Function __ymdts literal pool
         DS    0F
         LTORG
* Function __ymdts page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
