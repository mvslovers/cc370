         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func asin prologue
ASIN     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function asin code
         LD    4,0(11)
@@L4     EQU   *
         LTDR  4,4
         BL    @@L4
         CD    4,=D'1.0E+0'
         BNH   @@L5
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'33'
         LD    2,=D'9.999999999999999830337E+72'
         B     @@L1
@@L5     EQU   *
         L     12,0(,10)
         CD    4,=D'7.5E-1'
         BNH   @@L7
         MDR   4,4
         LD    0,=D'1.0E+0'
         SDR   0,4
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(SQRT)
         BALR  14,15
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ASIN)
         BALR  14,15
         LD    2,=D'1.57079632679489655799898E+0'
         SDR   2,0
         B     @@L1
@@L7     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
         STD   4,80(,13)
         LM    2,3,80(13)
         LM    4,5,=D'1.0E+0'
         LDR   6,4
@@L9     EQU   *
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         STD   0,80(,13)
         LM    8,9,80(13)
         STM   4,5,80(13)
         LD    2,80(,13)
         MDR   2,0
         AD    0,=D'1.0E+0'
         DDR   2,0
         STD   2,80(,13)
         LM    4,5,80(13)
         MDR   6,4
         MDR   6,4
         LDR   0,2
         MDR   0,6
         STM   8,9,80(13)
         LD    2,80(,13)
         AD    2,=D'2.0E+0'
         DDR   0,2
         STM   2,3,80(13)
         LD    2,80(,13)
         ADR   0,2
         CDR   2,0
         BE    @@L10
         STD   0,80(,13)
         LM    2,3,80(13)
         A     15,=F'2'
         B     @@L9
@@L10    EQU   *
         L     12,0(,10)
         STM   2,3,80(13)
         LD    2,80(,13)
@@L1     EQU   *
         L     12,0(,10)
         LDR   0,2
* Function asin epilogue
         PDPEPIL
* Function asin literal pool
         DS    0F
         LTORG
* Function asin page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
