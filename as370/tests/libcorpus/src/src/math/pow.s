         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func pow prologue
POW      PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function pow code
         LD    6,0(11)
         LD    2,8(11)
         SLR   2,2
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     15,84(,13)
         MVC   80(4,13),=XL4'4E000000'
         ST    15,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         CDR   0,2
         BNE   @@L2
         LDR   4,6
         LTDR  2,2
         BNL   @@L4
         LA    2,1(0,0)
         LCR   15,15
@@L4     EQU   *
         L     12,0(,10)
         LD    0,=D'1.0E+0'
         LTDR  2,2
         BE    @@L1
@@L18    EQU   *
         BCTR  15,0
         LTR   15,15
         BNH   @@L17
         MDR   4,6
         B     @@L18
@@L17    EQU   *
         L     12,0(,10)
         LTR   2,2
         BE    @@L11
         LD    0,=D'1.0E+0'
         DDR   0,4
         LDR   4,0
@@L11    EQU   *
         L     12,0(,10)
         LDR   0,4
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LTDR  6,6
         BNL   @@L12
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'33'
         LD    0,=D'0.0'
         B     @@L1
@@L12    EQU   *
         L     12,0(,10)
         LD    0,=D'1.0E+0'
         LTDR  2,2
         BE    @@L1
         STD   6,88(13)
         STD   2,96(13)
         LA    1,88(,13)
         L     15,=V(LOG)
         BALR  14,15
         LD    2,96(13)
         MDR   2,0
         STD   2,88(13)
         LA    1,88(,13)
         L     15,=V(EXP)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function pow epilogue
         PDPEPIL
* Function pow literal pool
         DS    0F
         LTORG
* Function pow page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
