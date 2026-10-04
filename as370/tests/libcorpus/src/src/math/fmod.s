         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fmod prologue
FMOD     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fmod code
         LM    8,9,0(11)
         LD    2,8(11)
         LR    6,8
         LR    7,9
         STM   8,9,80(13)
         LD    0,80(,13)
         LTDR  0,0
         BNL   @@L2
         LCDR  0,0
         STD   0,80(,13)
         LM    6,7,80(13)
@@L2     EQU   *
         L     12,0(,10)
         LPDR  0,2
         STD   0,80(,13)
         LM    4,5,80(13)
         LD    0,=D'0.0'
         LTDR  2,2
         BE    @@L1
         STM   6,7,80(13)
         LD    6,80(,13)
         STM   4,5,80(13)
         LD    2,80(,13)
         DDR   6,2
         LDR   4,6
         CD    6,=D'4.503599627370496E+15'
         BNL   @@L10
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
@@L10    EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
         MDR   4,0
         STM   6,7,80(13)
         LD    2,80(,13)
         SDR   2,4
         LDR   4,2
         BNL   @@L11
         ADR   4,0
@@L11    EQU   *
         L     12,0(,10)
         STM   4,5,80(13)
         LD    0,80(,13)
         CDR   4,0
         BL    @@L13
         SDR   4,0
@@L13    EQU   *
         L     12,0(,10)
         LTDR  4,4
         BL    @@L16
         STM   4,5,80(13)
         LD    2,80(,13)
         CDR   4,2
         BL    @@L15
@@L16    EQU   *
         L     12,0(,10)
         LD    4,=D'0.0'
@@L15    EQU   *
         L     12,0(,10)
         LDR   0,4
         STM   8,9,80(13)
         LD    2,80(,13)
         LTDR  2,2
         BNL   @@L1
         LCDR  0,4
@@L1     EQU   *
         L     12,0(,10)
* Function fmod epilogue
         PDPEPIL
* Function fmod literal pool
         DS    0F
         LTORG
* Function fmod page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
