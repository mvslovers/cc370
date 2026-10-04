         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wto prologue
WTO      PDPPRLG CINDEX=0,FRAME=232,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wto code
         L     9,0(11)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    8,15
@@L2     EQU   *
         LA    2,124(0,0)
         CR    8,2
         BH    @@L5
         A     8,=F'4'
         STH   8,96(13)
         A     8,=F'-4'
         MVC   98(2,13),=H'0'
         BNH   @@L6
         LA    4,100(,13)
         LR    5,8
         LR    2,9
         LR    3,8
         MVCL  4,2
@@L6     EQU   *
         L     12,0(,10)
         SLR   8,8
         B     @@L7
@@L5     EQU   *
         L     12,0(,10)
         LR    15,9
         A     15,=F'124'
         LR    2,15
         B     @@L17
@@L16    EQU   *
         CLR   15,9
         BNH   @@L9
         BCTR  15,0
@@L17    EQU   *
         L     12,0(,10)
         CLI   0(15),64
         BNE   @@L16
@@L9     EQU   *
         L     12,0(,10)
         CLR   15,9
         BNE   @@L11
         LR    15,2
         B     @@L12
@@L11    EQU   *
         L     12,0(,10)
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'64'
         BNE   @@L12
         A     15,=F'1'
@@L12    EQU   *
         L     12,0(,10)
         LR    2,15
         SR    2,9
         SLL   2,16
         SRA   2,16
         STH   2,96(13)
         MVC   98(2,13),=H'0'
         LA    6,100(,13)
         LR    7,2
         LR    4,9
         LR    5,2
         MVCL  6,4
         LH    2,96(13)
         SLR   3,3
         STC   3,100(2,13)
         SR    8,2
         BNH   @@L14
         LR    4,9
         LR    5,8
         LR    2,15
         LR    3,8
         MVCL  4,2
@@L14    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,0(8,9)
         LH    2,96(13)
         AH    2,=H'4'
         STH   2,96(13)
@@L7     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTOLINE)
         BALR  14,15
         LTR   8,8
         BH    @@L2
* Function wto epilogue
         PDPEPIL
* Function wto literal pool
         DS    0F
         LTORG
* Function wto page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
