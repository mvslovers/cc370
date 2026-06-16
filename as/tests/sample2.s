         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func f prologue
F        PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function f code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(G)
         BALR  14,15
         A     15,=F'1'
* Function f epilogue
         PDPEPIL
* Function f literal pool
         DS    0F
         LTORG
* Function f page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
