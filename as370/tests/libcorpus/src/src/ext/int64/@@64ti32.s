         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_to_i32'
* Program text area
         DS    0F
* X-func *@@64TI32 prologue
@@64TI32 PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64TI32 code
         L     2,0(11)
         SLR   15,15
         LTR   2,2
         BE    @@L2
         L     15,4(2)
         N     15,=F'2147483647'
@@L2     EQU   *
         L     12,0(,10)
* Function *@@64TI32 epilogue
         PDPEPIL
* Function *@@64TI32 literal pool
         DS    0F
         LTORG
* Function *@@64TI32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
