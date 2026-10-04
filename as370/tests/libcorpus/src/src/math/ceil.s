         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func ceil prologue
CEIL     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function ceil code
         LM    4,5,0(11)
         STM   4,5,80(13)
         LD    0,80(,13)
         LTDR  0,0
         BNH   @@L2
         STM   4,5,80(13)
         LD    6,80(,13)
         CD    0,=D'4.503599627370496E+15'
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
         LDR   0,6
         STM   4,5,80(13)
         LD    2,80(,13)
         CDR   6,2
         BE    @@L1
         AD    0,=D'1.0E+0'
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
         LCDR  6,0
         LDR   4,6
         CD    6,=D'4.503599627370496E+15'
         BNL   @@L11
         LDR   2,6
         MD    2,=D'2.3283064365386962890625E-10'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     2,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    4,80(,13)
         SD    4,=XL8'4E00000080000000'
         MD    4,=D'4.294967296E+9'
         SDR   6,4
         LDR   2,6
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
         SDR   6,0
         ADR   4,0
         LDR   0,6
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     2,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         ADR   4,0
@@L11    EQU   *
         L     12,0(,10)
         LCDR  0,4
@@L1     EQU   *
         L     12,0(,10)
* Function ceil epilogue
         PDPEPIL
* Function ceil literal pool
         DS    0F
         LTORG
* Function ceil page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
