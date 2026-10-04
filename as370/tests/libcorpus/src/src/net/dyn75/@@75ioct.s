         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ioctlsocket'
* Program text area
         DS    0F
* X-func *@@75IOCT prologue
@@75IOCT PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75IOCT code
         L     5,0(11)
         L     2,4(11)
         L     4,8(11)
         LA    3,96(,13)
         XC    0(64,3),0(3)     clear __75 parameter list
         LR    3,5
         SLL   3,16
         O     3,=F'15'
         ST    3,124(13)
         ST    2,128(13)
         ST    4,132(13)
         LA    3,96(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    6,1(0,0)
         CLR   2,6
         BE    @@L3
         L     2,112(13)
         L     6,=F'-1'
         CLR   2,6
         BNE   @@L3
         MVC   100(4,13),=F'0'
         MVC   124(4,13),=F'2'
         ST    5,128(13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
         B     @@L5
@@L3     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L6
         MVC   0(4,4),112(13)
@@L6     EQU   *
         L     12,0(,10)
         SLR   2,2
@@L5     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@75IOCT epilogue
         PDPEPIL
* Function *@@75IOCT literal pool
         DS    0F
         LTORG
* Function *@@75IOCT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
