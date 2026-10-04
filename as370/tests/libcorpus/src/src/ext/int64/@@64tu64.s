         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_to_u64'
* Program text area
         DS    0F
* X-func *@@64TU64 prologue
@@64TU64 PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64TU64 code
         LR    4,0
         L     15,0(11)
         SLR   2,2
         SLR   3,3
         LTR   15,15
         BE    @@L2
         L     2,0(15)
         L     3,4+0(15)
@@L2     EQU   *
         L     12,0(,10)
         ST    2,0(4)
         ST    3,4+0(4)
         LR    15,0
* Function *@@64TU64 epilogue
         PDPEPIL
* Function *@@64TU64 literal pool
         DS    0F
         LTORG
* Function *@@64TU64 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
