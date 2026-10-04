         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func cosh prologue
COSH     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function cosh code
         MVC   88(8,13),0(11)
         LA    1,88(,13)
         L     15,=V(EXP)
         BALR  14,15
         LD    2,=D'1.0E+0'
         DDR   2,0
         ADR   2,0
         LDR   0,2
         MD    0,=D'5.0E-1'
* Function cosh epilogue
         PDPEPIL
* Function cosh literal pool
         DS    0F
         LTORG
* Function cosh page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
