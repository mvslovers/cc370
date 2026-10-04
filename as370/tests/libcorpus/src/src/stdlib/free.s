         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func free prologue
FREE     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function free code
         L     15,0(11)
         LTR   15,15
         BE    @@L1
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@FREEM)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function free epilogue
         PDPEPIL
* Function free literal pool
         DS    0F
         LTORG
* Function free page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
