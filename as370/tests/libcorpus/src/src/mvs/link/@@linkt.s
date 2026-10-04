         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __linkt prologue
@@LINKT  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __linkt code
         MVC   88(4,13),=V(@@LINK)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         MVC   100(4,13),8(11)
         MVC   104(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
* Function __linkt epilogue
         PDPEPIL
* Function __linkt literal pool
         DS    0F
         LTORG
* Function __linkt page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
