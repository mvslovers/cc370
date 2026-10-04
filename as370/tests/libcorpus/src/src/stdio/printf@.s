         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'printf_'
* Program text area
         DS    0F
* X-func printf_ prologue
PRINTF@  PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function printf_ code
         L     2,=V(@@PRTFX)
         L     3,0(2)
         MVC   88(4,13),8(3)
         LA    2,112(,13)
         ST    2,92(13)
         MVC   96(4,13),=F'-1'
         MVC   100(4,13),0(11)
         LA    2,4(,11)
         ST    2,104(13)
         L     2,44(3)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
* Function printf_ epilogue
         PDPEPIL
* Function printf_ literal pool
         DS    0F
         LTORG
* Function printf_ page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
