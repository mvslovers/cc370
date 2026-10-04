         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func sin prologue
SIN      PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function sin code
         LD    4,0(11)
         LDR   2,4
         DD    2,=D'6.28318530717958667608514E+0'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     15,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         MD    0,=D'6.28318530717958667608514E+0'
         SDR   4,0
         STD   4,80(,13)
         LM    2,3,80(13)
         LA    15,1(0,0)
         LDR   6,4
@@L2     EQU   *
         A     15,=F'1'
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         BCTR  15,0
         STM   2,3,80(13)
         LD    0,80(,13)
         MDR   6,0
         MDR   6,0
         LCDR  6,6
         LDR   0,2
         AD    0,=D'1.0E+0'
         MDR   2,0
         DDR   6,2
         LDR   0,4
         ADR   0,6
         CDR   4,0
         BE    @@L3
         LDR   4,0
         A     15,=F'2'
         B     @@L2
@@L3     EQU   *
         L     12,0(,10)
         LDR   0,4
* Function sin epilogue
         PDPEPIL
* Function sin literal pool
         DS    0F
         LTORG
* Function sin page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
