         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func modf prologue
MODF     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function modf code
         LM    4,5,0(11)
         SLR   15,15
         STM   4,5,80(13)
         LD    0,80(,13)
         LTDR  0,0
         BNL   @@L2
         LA    15,1(0,0)
         LCDR  0,0
         STD   0,80(,13)
         LM    4,5,80(13)
@@L2     EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    6,80(,13)
         CD    6,=D'4.503599627370496E+15'
         BNL   @@L6
         STM   4,5,80(13)
         LD    2,80(,13)
         MD    2,=D'2.3283064365386962890625E-10'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     2,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    6,80(,13)
         SD    6,=XL8'4E00000080000000'
         MD    6,=D'4.294967296E+9'
         STM   4,5,80(13)
         LD    4,80(,13)
         SDR   4,6
         LDR   2,4
         MD    2,=D'1.52587890625E-5'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     2,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         MD    0,=D'6.5536E+4'
         SDR   4,0
         ADR   6,0
         LDR   0,4
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     2,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         ADR   6,0
@@L6     EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
         SDR   0,6
         STD   0,80(,13)
         LM    4,5,80(13)
         LTR   15,15
         BE    @@L7
         LCDR  0,0
         STD   0,80(,13)
         LM    4,5,80(13)
         LCDR  6,6
@@L7     EQU   *
         L     12,0(,10)
         L     2,8(11)
         STD   6,0(2)
         STM   4,5,80(13)
         LD    0,80(,13)
* Function modf epilogue
         PDPEPIL
* Function modf literal pool
         DS    0F
         LTORG
* Function modf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
