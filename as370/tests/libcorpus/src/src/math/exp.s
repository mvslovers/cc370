         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func exp prologue
EXP      PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function exp code
         LD    6,0(11)
         LA    15,2(0,0)
         LDR   4,6
         LDR   2,6
@@L2     EQU   *
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         MDR   2,6
         DDR   2,0
         LDR   0,4
         ADR   0,2
         CDR   4,0
         BE    @@L3
         LDR   4,0
         A     15,=F'1'
         B     @@L2
@@L3     EQU   *
         L     12,0(,10)
         LDR   0,4
         AD    0,=D'1.0E+0'
* Function exp epilogue
         PDPEPIL
* Function exp literal pool
         DS    0F
         LTORG
* Function exp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
