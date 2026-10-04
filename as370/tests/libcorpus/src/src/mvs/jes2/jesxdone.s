         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesxdone prologue
JESXDONE PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesxdone code
         L     2,0(11)
         LA    3,96(,13)
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(INITSSOB)
         BALR  14,15
         MVC   102(2,13),=H'1'
         MVI   4(2),0
         MVI   5(2),128
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(IEFSSREQ)
         BALR  14,15
@@L2     EQU   *
         L     15,108(13)
* Function jesxdone epilogue
         PDPEPIL
* Function jesxdone literal pool
         DS    0F
         LTORG
* Function jesxdone page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
