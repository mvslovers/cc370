         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func wtor prologue
WTOR     PDPPRLG CINDEX=0,FRAME=240,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wtor code
         L     8,0(11)
         L     6,4(11)
         L     7,8(11)
         MVC   232(4,13),=F'0'
         SLR   15,15
         LA    4,96(,13)
         LA    5,136(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LTR   7,7
         BE    @@L2
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,122(0,0)
         CLR   15,2
         BNH   @@L2
         LR    15,2
@@L2     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L4
         LTR   6,6
         BE    @@L4
         LA    2,119(0,0)
         CLR   6,2
         BNH   @@L5
         LR    6,2
@@L5     EQU   *
         L     12,0(,10)
         ST    8,96(13)
         STC   6,96(13)
         LA    2,232(,13)
         ST    2,100(13)
@@L4     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L6
         A     15,=F'4'
         STH   15,104(13)
         A     15,=F'-4'
         LA    4,108(,13)
         LR    5,15
         LR    2,7
         LR    3,15
         MVCL  4,2
@@L6     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         LR    1,2
         SVC   35
         L     2,100(13)
         LTR   2,2
         BE    @@L1
         WAIT  1,ECB=(2)
@@L1     EQU   *
         L     12,0(,10)
* Function wtor epilogue
         PDPEPIL
* Function wtor literal pool
         DS    0F
         LTORG
* Function wtor page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
