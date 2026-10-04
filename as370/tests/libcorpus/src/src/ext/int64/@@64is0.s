         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_is_zero'
* Program text area
         DS    0F
* X-func *@@64IS0 prologue
@@64IS0  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64IS0 code
         L     2,0(11)
         LTR   2,2
         BE    @@L2
         L     3,0(2)
         O     3,4(2)
         SLR   15,15
         LTR   3,3
         BNE   @@L1
@@L2     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64IS0 epilogue
         PDPEPIL
* Function *@@64IS0 literal pool
         DS    0F
         LTORG
* Function *@@64IS0 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
