         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'send'
* Program text area
         DS    0F
* X-func *@@75SEND prologue
@@75SEND PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75SEND code
         L     7,0(11)
         L     6,4(11)
         L     5,8(11)
         SLR   3,3
@@L2     EQU   *
         LA    2,96(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         ST    5,100(13)
         ST    6,116(13)
         MVC   124(4,13),=F'10'
         ST    7,128(13)
         LA    4,96(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     2,112(13)
         L     8,=F'-2'
         CR    2,8
         BNE   @@L3
         A     3,=F'1'
         LA    2,100(0,0)
         CR    3,2
         BNH   @@L5
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'35'
         L     2,=F'-1'
         B     @@L6
@@L5     EQU   *
         STIMER WAIT,BINTVL==F'10'  0.10 seconds
         L     12,0(,10)
         B     @@L2
@@L3     EQU   *
         L     12,0(,10)
         L     3,=F'-1'
         CLR   2,3
         BNE   @@L6
         MVC   100(4,13),=F'0'
         MVC   124(4,13),=F'2'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
@@L6     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@75SEND epilogue
         PDPEPIL
* Function *@@75SEND literal pool
         DS    0F
         LTORG
* Function *@@75SEND page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
