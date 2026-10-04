         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wcstombs prologue
WCSTOMBS PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wcstombs code
         L     5,0(11)
         L     6,8(11)
         SLR   15,15
         LTR   5,5
         BE    @@L11
         CLR   15,6
         BNL   @@L12
@@L11    EQU   *
         L     12,0(,10)
         LR    3,5
         L     4,4(11)
@@L16    EQU   *
         L     2,0(4)
         LTR   2,2
         BNE   @@L6
         LTR   5,5
         BE    @@L1
         STC   2,0(3)
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         LA    7,255(0,0)
         CLR   2,7
         BNH   @@L8
         L     15,=F'-1'
         B     @@L1
@@L8     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L4
         STC   2,0(3)
@@L4     EQU   *
         L     12,0(,10)
         A     15,=F'1'
         A     4,=F'4'
         A     3,=F'1'
         LTR   5,5
         BE    @@L16
         CLR   15,6
         BL    @@L16
@@L12    EQU   *
         L     12,0(,10)
         LR    15,6
@@L1     EQU   *
         L     12,0(,10)
* Function wcstombs epilogue
         PDPEPIL
* Function wcstombs literal pool
         DS    0F
         LTORG
* Function wcstombs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
