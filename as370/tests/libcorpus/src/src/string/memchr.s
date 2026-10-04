         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memchr prologue
MEMCHR   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memchr code
         L     4,4(11)
         L     3,8(11)
         SLR   2,2
         L     15,0(11)
@@L8     EQU   *
         CLR   2,3
         BNL   @@L7
         CLM   4,1,0(15)
         BE    @@L1
         A     15,=F'1'
         A     2,=F'1'
         B     @@L8
@@L7     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function memchr epilogue
         PDPEPIL
* Function memchr literal pool
         DS    0F
         LTORG
* Function memchr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
