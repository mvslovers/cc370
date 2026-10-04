         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func mbtowc prologue
MBTOWC   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mbtowc code
         L     4,0(11)
         L     3,4(11)
         LR    15,3
         LTR   3,3
         BE    @@L1
         L     15,=F'-1'
         L     2,8(11)
         LTR   2,2
         BE    @@L1
         LTR   4,4
         BE    @@L4
         SLR   2,2
         IC    2,0(3)
         ST    2,0(4)
@@L4     EQU   *
         L     12,0(,10)
         SLR   15,15
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L1
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function mbtowc epilogue
         PDPEPIL
* Function mbtowc literal pool
         DS    0F
         LTORG
* Function mbtowc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
