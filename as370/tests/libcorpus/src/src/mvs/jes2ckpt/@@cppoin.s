         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __cppoin prologue
@@CPPOIN PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cppoin code
         L     2,0(11)
         L     15,=F'-1'
         LTR   2,2
         BE    @@L2
         L     3,16(2)
         IC    2,48(3)
         N     2,=F'16'
         LTR   2,2
         BE    @@L2
         LA    2,4(,11)
         POINT (3),(2)
         SLR   15,15
@@L2     EQU   *
         L     12,0(,10)
* Function __cppoin epilogue
         PDPEPIL
* Function __cppoin literal pool
         DS    0F
         LTORG
* Function __cppoin page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
