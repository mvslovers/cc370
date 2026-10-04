         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'in __75exit(), inuse=%08X'
         DC    X'15'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%02X '
         DC    X'0'
@@LC2    EQU   *
         DC    C'closing socket %d'
         DC    X'15'
         DC    X'0'
@@LC3    EQU   *
         DC    C'socket %d is not in use'
         DC    X'15'
         DC    X'0'
@@LC4    EQU   *
         DC    C'leaving __75exit()'
         DC    X'0'
         DS    0F
* X-func __75exit prologue
@@75EXIT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __75exit code
         MVC   88(4,13),=A(@@LC0)
         L     7,=V(@@75VECT)
         L     2,0(7)
         MVC   92(4,13),8(2)
         LA    1,88(,13)
         L     15,=V(PRINTF)
         BALR  14,15
         L     2,0(7)
         L     3,8(2)
         LTR   3,3
         BE    @@L2
         SLR   6,6
@@L6     EQU   *
         MVC   88(4,13),=A(@@LC1)
         SLR   2,2
         IC    2,0(6,3)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(PRINTF)
         BALR  14,15
         A     6,=F'1'
         LA    2,127(0,0)
         CLR   6,2
         BNH   @@L6
         MVC   88(4,13),=F'21'
         LA    1,88(,13)
         L     15,=V(PUTCHAR)
         BALR  14,15
         SLR   6,6
@@L12    EQU   *
         L     2,0(7)
         L     5,8(2)
         LR    3,6
         SRL   3,5
         SLL   3,2
         LR    4,6
         N     4,=F'31'
         LA    2,1(0,0)
         SLL   2,0(4)
         N     2,0(3,5)
         LTR   2,2
         BE    @@L10
         MVC   88(4,13),=A(@@LC2)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(PRINTF)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75CLOS)
         BALR  14,15
         B     @@L9
@@L10    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC3)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(PRINTF)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         A     6,=F'1'
         LA    2,1023(0,0)
         CR    6,2
         BNH   @@L12
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(PUTS)
         BALR  14,15
* Function __75exit epilogue
         PDPEPIL
* Function __75exit literal pool
         DS    0F
         LTORG
* Function __75exit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
