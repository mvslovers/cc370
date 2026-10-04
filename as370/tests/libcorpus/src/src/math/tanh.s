         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func tanh prologue
TANH     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tanh code
         LD    0,0(11)
         MD    0,=D'-2.0E+0'
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(EXP)
         BALR  14,15
         LDR   2,0
         LD    0,=D'1.0E+0'
         SDR   0,2
         AD    2,=D'1.0E+0'
         DDR   0,2
* Function tanh epilogue
         PDPEPIL
* Function tanh literal pool
         DS    0F
         LTORG
* Function tanh page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
