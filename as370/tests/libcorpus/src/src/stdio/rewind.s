         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func rewind prologue
REWIND   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function rewind code
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(FSEEK)
         BALR  14,15
* Function rewind epilogue
         PDPEPIL
* Function rewind literal pool
         DS    0F
         LTORG
* Function rewind page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
