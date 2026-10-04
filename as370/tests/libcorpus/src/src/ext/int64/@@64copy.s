         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_copy'
* Program text area
         DS    0F
* X-func *@@64COPY prologue
@@64COPY PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64COPY code
         L     2,0(11)
         L     15,4(11)
         LTR   2,2
         BE    @@L1
         LTR   15,15
         BE    @@L1
         MVC   0(8,15),0(2)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64COPY epilogue
         PDPEPIL
* Function *@@64COPY literal pool
         DS    0F
         LTORG
* Function *@@64COPY page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
