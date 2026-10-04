         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func sleep prologue
SLEEP    PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function sleep code
         L     15,0(11)
         MVC   104(4,13),=F'0'
         LTR   15,15
         BE    @@L2
         LA    2,104(,13)
         ST    2,88(13)
         MH    15,=H'100'
         ST    15,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ECBTW)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function sleep epilogue
         PDPEPIL
* Function sleep literal pool
         DS    0F
         LTORG
* Function sleep page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
