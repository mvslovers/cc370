         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func atan prologue
ATAN     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function atan code
         LD    4,0(11)
@@L4     EQU   *
         LTDR  4,4
         BL    @@L4
         CD    4,=D'1.0E+0'
         BNH   @@L5
         LD    0,=D'1.0E+0'
         DDR   0,4
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LD    2,=D'1.57079632679489655799898E+0'
         SDR   2,0
         B     @@L1
@@L5     EQU   *
         L     12,0(,10)
         CD    4,=D'2.67949192431122806823396E-1'
         BNH   @@L7
         LDR   0,4
         MD    0,=D'1.7320508075688771931766E+0'
         SD    0,=D'1.0E+0'
         AD    4,=D'1.7320508075688771931766E+0'
         DDR   0,4
         STD   0,88(13)
         LA    1,88(,13)
         L     15,=V(ATAN)
         BALR  14,15
         LDR   2,0
         AD    2,=D'5.23598775598298885047832E-1'
         B     @@L1
@@L7     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
         LDR   6,4
         STD   4,80(,13)
         LM    2,3,80(13)
@@L9     EQU   *
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         STM   2,3,80(13)
         LD    0,80(,13)
         MDR   0,4
         MDR   0,4
         LCDR  0,0
         STD   0,80(,13)
         LM    2,3,80(13)
         AD    2,=D'2.0E+0'
         DDR   0,2
         LDR   2,0
         ADR   2,6
         CDR   6,2
         BE    @@L10
         LDR   6,2
         A     15,=F'2'
         B     @@L9
@@L10    EQU   *
         L     12,0(,10)
         LDR   2,6
@@L1     EQU   *
         L     12,0(,10)
         LDR   0,2
* Function atan epilogue
         PDPEPIL
* Function atan literal pool
         DS    0F
         LTORG
* Function atan page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
