         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesxwrtr prologue
JESXWRTR PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesxwrtr code
         L     4,0(11)
         L     5,4(11)
         L     6,8(11)
         L     7,12(11)
         L     9,=F'-1'
         LTR   4,4
         BE    @@L3
         LA    8,104(,13)
         ST    8,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(INITSSOB)
         BALR  14,15
         MVC   110(2,13),=H'1'
         SLR   3,3
         LA    2,120(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         MVC   0(2,4),=H'120'
         LTR   5,5
         BE    @@L5
         LR    2,4
         A     2,=F'100'
         ST    2,88(13)
         MVC   92(4,13),=F'8'
         ST    5,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         CLI   0(2),64
         BNH   @@L5
         OI    4(4),64
@@L5     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L7
         LR    2,4
         A     2,=F'28'
         ST    2,88(13)
         MVC   92(4,13),=F'8'
         ST    6,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         CLI   0(2),64
         BNH   @@L7
         OI    4(4),32
@@L7     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L9
         LR    2,4
         A     2,=F'96'
         ST    2,88(13)
         MVC   92(4,13),=F'4'
         ST    7,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         CLI   0(2),64
         BNH   @@L9
         OI    4(4),2
@@L9     EQU   *
         L     12,0(,10)
         IC    2,4(4)
         CLM   2,1,=XL1'00'
         BE    @@L3
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(IEFSSREQ)
         BALR  14,15
         L     9,116(13)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,9
* Function jesxwrtr epilogue
         PDPEPIL
* Function jesxwrtr literal pool
         DS    0F
         LTORG
* Function jesxwrtr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
