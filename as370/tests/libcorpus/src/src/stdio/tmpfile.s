         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'wb'
         DC    X'0'
         DS    0F
* X-func tmpfile prologue
TMPFILE  PDPPRLG CINDEX=0,FRAME=360,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tmpfile code
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(TMPNAM)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
* Function tmpfile epilogue
         PDPEPIL
* Function tmpfile literal pool
         DS    0F
         LTORG
* Function tmpfile page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
