         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'DSN=%s;DISP=SHR'
         DC    X'0'
@@LC1    EQU   *
         DC    C'write'
         DC    X'0'
         DS    0F
* X-func __renmem prologue
@@RENMEM PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __renmem code
         L     15,0(11)
         L     8,4(11)
         L     9,8(11)
         L     7,=F'-1'
         SLR   6,6
         LA    4,104(,13)
         LA    5,9(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LTR   15,15
         BE    @@L4
         LTR   8,8
         BE    @@L4
         LTR   9,9
         BE    @@L4
         CLI   0(8),64
         BNH   @@L4
         CLI   0(9),64
         BNH   @@L4
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(@@DSALCF)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L7
         L     7,=F'-2'
         B     @@L4
@@L7     EQU   *
         L     12,0(,10)
         LA    3,104(,13)
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(OSBDCB)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L9
         MVI   26(15),2
         STC   2,27(15)
         ST    15,88(13)
         ST    2,92(13)
         MVC   96(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(OSBOPEN)
         BALR  14,15
         L     7,=F'-3'
         LTR   15,15
         BNE   @@L11
         LA    7,120(,13)
         LA    3,64(0,0)
         LA    2,16(0,0)
         
*** MEMSET ***
         LR    14,7           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         CLI   0(8),64
         BNH   @@L14
         LR    4,8
         LR    5,7
         LR    15,8
         A     15,=F'7'
@@L16    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     5,=F'1'
         A     4,=F'1'
         CR    4,15
         BH    @@L14
         CLI   0(4),64
         BH    @@L16
@@L14    EQU   *
         L     12,0(,10)
         CLI   0(9),64
         BNH   @@L18
         LR    4,9
         LA    5,128(,13)
         LR    15,9
         A     15,=F'7'
@@L20    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(5)
         A     5,=F'1'
         A     4,=F'1'
         CR    4,15
         BH    @@L18
         CLI   0(4),64
         BH    @@L20
@@L18    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    7,92(13)
         MVC   96(4,13),=F'195'
         LA    1,88(,13)
         L     15,=V(@@STOW)
         BALR  14,15
         LR    7,15
@@L11    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'1'
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(OSBCLOSE)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@DSFREE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,7
* Function __renmem epilogue
         PDPEPIL
* Function __renmem literal pool
         DS    0F
         LTORG
* Function __renmem page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
