         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func tan prologue
TAN      PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tan code
         LD    0,0(11)
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(COS)
         BALR  14,15
         STD   0,80(,13)
         LM    2,3,80(13)
         LD    0,=D'9.999999999999999830337E+72'
         STM   2,3,80(13)
         LD    2,80(,13)
         LTDR  2,2
         BE    @@L1
         LD    0,0(11)
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(SIN)
         BALR  14,15
         STM   2,3,80(13)
         LD    2,80(,13)
         DDR   0,2
@@L1     EQU   *
         L     12,0(,10)
* Function tan epilogue
         PDPEPIL
* Function tan literal pool
         DS    0F
         LTORG
* Function tan page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
