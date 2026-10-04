         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'connect'
* Program text area
         DS    0F
* X-func *@@75CONN prologue
@@75CONN PDPPRLG CINDEX=0,FRAME=192,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75CONN code
         L     9,4(11)
         LA    5,104(,13)
         XC    0(64,5),0(5)     clear __75 parameter list
         MVC   132(4,13),=F'1'
         SLR   4,4
@@L8     EQU   *
         MVC   108(4,13),=F'0'
         L     2,132(13)
         SLL   2,24
         SRL   2,16
         A     2,=F'7'
         L     3,0(11)
         SLL   3,16
         AR    2,3
         ST    2,132(13)
         MVC   136(4,13),4(9)
         LH    2,0(9)
         SLL   2,16
         LH    3,2(9)
         N     3,=XL4'0000FFFF'
         OR    2,3
         N     2,=F'16777215'
         ST    2,140(13)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     3,120(13)
         L     2,=F'-2'
         CLR   3,2
         BNE   @@L3
         SLR   2,2
         IC    2,134(13)
         ST    2,132(13)
         LTR   2,2
         BE    @@L11
         BCTR  2,0
         ST    2,132(13)
         STIMER WAIT,BINTVL==F'100'     1.00 seconds
         A     4,=F'1'
         LA    2,1(0,0)
         CR    4,2
         BNH   @@L8
@@L3     EQU   *
         L     12,0(,10)
         LR    8,3
         LTR   3,3
         BL    @@L9
         LA    3,168(,13)
         LR    6,3
         LA    7,16(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         MVC   184(4,13),=F'16'
         MVC   88(4,13),0(11)
         ST    3,92(13)
         LA    2,184(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@75SNAM)
         BALR  14,15
         MVC   88(4,13),0(11)
         ST    3,92(13)
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(@@SOUPD)
         BALR  14,15
         B     @@L7
@@L11    EQU   *
         L     12,0(,10)
         L     8,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'61'
         B     @@L7
@@L9     EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'0'
         MVC   136(4,13),0(11)
         MVC   132(4,13),=F'2'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),120(13)
@@L7     EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@75CONN epilogue
         PDPEPIL
* Function *@@75CONN literal pool
         DS    0F
         LTORG
* Function *@@75CONN page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
