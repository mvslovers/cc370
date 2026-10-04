         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'%*.*sDump of %08X "%s" (%d bytes)'
         DC    X'15'
         DC    X'0'
@@LC1    EQU   *
         DC    X'0'
@@LC2    EQU   *
         DC    C'%*.*s+%05X %-*.*s :%-*.*s:'
         DC    X'15'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%02X'
         DC    X'0'
@@LC4    EQU   *
         DC    C' '
         DC    X'0'
@@LC5    EQU   *
         DC    C'%c'
         DC    X'0'
         DS    0F
* X-func wtodump prologue
WTODUMP  PDPPRLG CINDEX=0,FRAME=312,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function wtodump code
         L     9,8(11)
         L     6,12(11)
         SLR   8,8
         ST    8,304(13)
         LR    3,6
         AR    3,6
         LR    2,6
         LTR   6,6
         BNL   @@L2
         A     2,=F'3'
@@L2     EQU   *
         L     12,0(,10)
         LR    4,2
         SRA   4,2
         AR    4,3
         BCTR  4,0
         L     7,4(11)
         MVC   88(4,13),=A(@@LC0)
         ST    8,92(13)
         ST    8,96(13)
         MVC   100(4,13),=A(@@LC1)
         ST    7,104(13)
         MVC   108(4,13),0(11)
         ST    9,112(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    8,300(13)
         ST    8,296(13)
         LTR   9,9
         BNH   @@L1
@@L12    EQU   *
         L     2,296(13)
         CLR   2,6
         BNE   @@L6
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=A(@@LC1)
         MVC   104(4,13),300(13)
         ST    4,108(13)
         ST    4,112(13)
         LA    2,136(,13)
         ST    2,116(13)
         ST    6,120(13)
         ST    6,124(13)
         LA    2,216(,13)
         ST    2,128(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         L     3,300(13)
         AR    3,6
         ST    3,300(13)
         SLR   8,8
         ST    8,296(13)
         ST    8,304(13)
@@L6     EQU   *
         L     12,0(,10)
         LA    2,136(,13)
         AR    2,8
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC3)
         SLR   2,2
         IC    2,0(7)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         AR    8,15
         L     2,296(13)
         N     2,=F'3'
         LA    3,3(0,0)
         CLR   2,3
         BNE   @@L7
         L     2,=A(@@LC4)
         LH    2,0(2)
         STH   2,136(13,8)
         A     8,=F'1'
@@L7     EQU   *
         L     12,0(,10)
         IC    5,0(7)
         LA    2,216(,13)
         A     2,304(13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC5)
         LR    15,5
         N     15,=XL4'000000FF'
         L     2,=V(@@ISBUF)
         L     3,0(2)
         LR    2,15
         AR    2,15
         LH    2,0(2,3)
         N     2,=F'16'
         LR    3,15
         LTR   2,2
         BNE   @@L9
         LR    2,15
         CLM   5,1,=XL1'40'
         BE    @@L11
         LA    2,75(0,0)
@@L11    EQU   *
         L     12,0(,10)
         LR    3,2
@@L9     EQU   *
         L     12,0(,10)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     15,304(13)
         ST    15,304(13)
         A     7,=F'1'
         BCTR  9,0
         L     2,296(13)
         A     2,=F'1'
         ST    2,296(13)
         LTR   9,9
         BH    @@L12
         LTR   8,8
         BE    @@L1
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=A(@@LC1)
         MVC   104(4,13),300(13)
         ST    4,108(13)
         ST    4,112(13)
         LA    2,136(,13)
         ST    2,116(13)
         ST    6,120(13)
         ST    6,124(13)
         LA    2,216(,13)
         ST    2,128(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L14    EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function wtodump epilogue
         PDPEPIL
* Function wtodump literal pool
         DS    0F
         LTORG
* Function wtodump page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
