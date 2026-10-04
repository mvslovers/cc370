         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBWSA '
         DC    X'0'
@@LC1    EQU   *
         DC    C'__wsaget() error adding new writable static area'
         DC    X'0'
@@LC2    EQU   *
         DC    C'__wsaget() out of memory for requested size %u b'
         DC    C'ytes'
         DC    X'0'
         DS    0F
* X-func __wsaget prologue
@@WSAGET PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __wsaget code
         L     9,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    7,15
         SLR   6,6
         L     4,4(11)
         A     4,=F'16'
         LR    15,6
         LTR   7,7
         BE    @@L1
         LR    8,7
         A     8,=F'68'
         ST    8,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L16
@@L7     EQU   *
         BCTR  15,0
         L     3,68(7)
         LR    2,15
         SLL   2,2
         L     6,0(2,3)
         LTR   6,6
         BE    @@L3
         L     2,8(6)
         CLR   2,9
         BNE   @@L6
         L     2,12(6)
         CLR   2,4
         BE    @@L4
@@L6     EQU   *
         L     12,0(,10)
         SLR   6,6
@@L3     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L7
@@L4     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNE   @@L8
@@L16    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L9
         L     2,=A(@@LC0)
         MVC   0(9,15),0(2)
         ST    9,8(15)
         ST    4,12(15)
         L     2,=F'8192'
         CLR   9,2
         BNH   @@L10
         L     2,=F'-16777217'
         CLR   9,2
         BH    @@L10
         LR    4,15
         A     4,=F'16'
         L     5,4(11)
         LR    2,9
         LR    3,5
         MVCL  4,2
@@L10    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L8
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   6,6
         B     @@L8
@@L9     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC2)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         A     7,=F'68'
         ST    7,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,6
         A     15,=F'16'
         LTR   6,6
         BNE   @@L1
         LR    15,6
@@L1     EQU   *
         L     12,0(,10)
* Function __wsaget epilogue
         PDPEPIL
* Function __wsaget literal pool
         DS    0F
         LTORG
* Function __wsaget page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
