         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func memmove prologue
MEMMOVE  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function memmove code
         L     15,0(11)
         L     5,4(11)
         L     6,8(11)
         LR    4,15
         LR    3,5
         CLR   15,5
         BH    @@L2
         SLR   2,2
         CLR   2,6
         BNL   @@L7
@@L6     EQU   *
         MVC   0(1,4),0(3)
         A     4,=F'1'
         A     3,=F'1'
         A     2,=F'1'
         CLR   2,6
         BL    @@L6
         B     @@L7
@@L2     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L7
         LR    2,6
@@L17    EQU   *
         BCTR  2,0
         LTR   2,2
         BE    @@L16
         IC    3,0(2,5)
         STC   3,0(2,15)
         B     @@L17
@@L16    EQU   *
         L     12,0(,10)
         IC    5,0(2,5)
         STC   5,0(2,15)
@@L7     EQU   *
         L     12,0(,10)
* Function memmove epilogue
         PDPEPIL
* Function memmove literal pool
         DS    0F
         LTORG
* Function memmove page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
