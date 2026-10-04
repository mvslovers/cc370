         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_lshift_one_bit'
* Program text area
         DS    0F
* X-func *@@64LSH1 prologue
@@64LSH1 PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64LSH1 code
         L     15,0(11)
         LTR   15,15
         BE    @@L1
         L     2,0(15)
         SLL   2,1
         L     3,4(15)
         LR    4,3
         SRL   4,31
         OR    2,4
         ST    2,0(15)
         SLL   3,1
         ST    3,4(15)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64LSH1 epilogue
         PDPEPIL
* Function *@@64LSH1 literal pool
         DS    0F
         LTORG
* Function *@@64LSH1 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
