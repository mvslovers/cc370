         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wtorf prologue
WTORF    PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wtorf code
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         LA    2,12(,11)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(VWTORF)
         BALR  14,15
* Function wtorf epilogue
         PDPEPIL
* Function wtorf literal pool
         DS    0F
         LTORG
* Function wtorf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
