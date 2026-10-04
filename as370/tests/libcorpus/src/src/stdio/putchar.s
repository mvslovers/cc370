         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func putchar prologue
PUTCHAR  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function putchar code
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         MVC   88(4,13),0(11)
         MVC   92(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(PUTC)
         BALR  14,15
* Function putchar epilogue
         PDPEPIL
* Function putchar literal pool
         DS    0F
         LTORG
* Function putchar page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
