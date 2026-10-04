         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'%d'
         DC    X'0'
         DS    0F
* X-func setenvi prologue
SETENVI  PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function setenvi code
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         MVC   96(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         MVC   88(4,13),0(11)
         ST    2,92(13)
         MVC   96(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(SETENV)
         BALR  14,15
* Function setenvi epilogue
         PDPEPIL
* Function setenvi literal pool
         DS    0F
         LTORG
* Function setenvi page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
