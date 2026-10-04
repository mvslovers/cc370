         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'getsockname'
* Program text area
@@LC0    EQU   *
         DC    X'0'
         DC    X'0'
         DC    X'0'
         DC    X'0'
         DC    X'0'
         DS    0F
* X-func *@@75SNAM prologue
@@75SNAM PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75SNAM code
         L     4,0(11)
         L     3,4(11)
         L     7,8(11)
         MVC   160(4,13),=F'0'
         SLR   8,8
         LTR   3,3
         BE    @@L2
         ST    4,88(13)
         LA    2,160(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@SOFIND)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         L     6,160(13)
         LTR   6,6
         BE    @@L2
         L     2,=A(@@LC0)
         CLC   16(4,6),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L2
         LA    15,16(0,0)
         LTR   7,7
         BE    @@L7
         L     15,0(7)
         LA    2,16(0,0)
         CLR   15,2
         BNH   @@L7
         LR    15,2
@@L7     EQU   *
         L     12,0(,10)
         LR    4,3
         LR    5,15
         LR    2,6
         A     2,=F'16'
         LR    3,15
         MVCL  4,2
         B     @@L8
@@L2     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         ST    3,120(13)
         MVC   124(4,13),=F'16'
         ST    4,128(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     8,112(13)
         L     3,=F'-1'
         CLR   8,3
         BNE   @@L8
         MVC   100(4,13),=F'0'
         MVC   124(4,13),=F'2'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
@@L8     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L10
         MVC   0(4,7),=F'16'
@@L10    EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@75SNAM epilogue
         PDPEPIL
* Function *@@75SNAM literal pool
         DS    0F
         LTORG
* Function *@@75SNAM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
