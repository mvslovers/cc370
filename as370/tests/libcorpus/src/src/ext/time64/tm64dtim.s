         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *TM64DTIM prologue
TM64DTIM PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64DTIM code
         LR    3,11
         LA    2,8(,11)
         ST    11,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         SLR   4,4
         L     5,=F'-1'
         CLR   15,5
         BNE   @@L3
         LA    4,1(0,0)
         LR    3,2
         LR    2,11
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    2,92(13)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SUB)
         BALR  14,15
         L     2,108(13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LTR   2,2
         BNL   @@L4
         AD    0,=D'4.294967296E+9'
@@L4     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L5
         LCDR  0,0
@@L5     EQU   *
         L     12,0(,10)
* Function *TM64DTIM epilogue
         PDPEPIL
* Function *TM64DTIM literal pool
         DS    0F
         LTORG
* Function *TM64DTIM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
