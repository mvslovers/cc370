         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func log prologue
LOG      PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function log code
         LD    2,0(11)
         LTDR  2,2
         BH    @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'33'
         LD    0,=D'9.999999999999999830337E+72'
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LD    0,=D'0.0'
         CD    2,=D'1.0E+0'
         BE    @@L1
         STD   2,88(13)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(FREXP)
         BALR  14,15
         SD    0,=D'1.0E+0'
         STD   0,80(,13)
         LM    4,5,80(13)
         LA    2,2(0,0)
         LDR   4,0
@@L6     EQU   *
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         STM   4,5,80(13)
         LD    6,80(,13)
         MDR   0,6
         LCDR  0,0
         LDR   6,0
         DDR   6,2
         LDR   2,6
         ADR   2,4
         CDR   4,2
         BE    @@L7
         LDR   4,2
         A     2,=F'1'
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         L     2,104(13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         MD    0,=D'6.9314718055994531398234E-1'
         ADR   0,4
@@L1     EQU   *
         L     12,0(,10)
* Function log epilogue
         PDPEPIL
* Function log literal pool
         DS    0F
         LTORG
* Function log page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
