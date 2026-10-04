         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'accept'
* Program text area
         DS    0F
* X-func *@@75ACCE prologue
@@75ACCE PDPPRLG CINDEX=0,FRAME=208,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75ACCE code
         L     3,0(11)
         L     2,4(11)
         LTR   2,2
         BNE   @@L2
         LA    2,168(,13)
         XC    0(16,2),0(2)     clear temp sockaddr_in
@@L2     EQU   *
         L     12,0(,10)
         LA    9,104(,13)
         XC    0(64,9),0(9)     clear __75 parameter list
@@L3     EQU   *
         MVC   108(4,13),=F'0'
         ST    2,128(13)
         MVC   132(4,13),=F'9'
         ST    3,136(13)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     8,120(13)
         L     4,=F'-2'
         CLR   8,4
         BNE   @@L4
         STIMER WAIT,BINTVL==F'8'   0.08 seconds
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         LTR   8,8
         BL    @@L6
         LA    2,184(,13)
         LR    6,2
         LA    7,16(0,0)
         SLR   4,4
         LR    5,4
         MVCL  6,4
         MVC   200(4,13),=F'16'
         ST    8,88(13)
         ST    2,92(13)
         LA    3,200(,13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@75SNAM)
         BALR  14,15
         ST    8,88(13)
         ST    2,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@SOADD)
         BALR  14,15
         ST    8,88(13)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@75PNAM)
         BALR  14,15
         ST    8,88(13)
         MVC   92(4,13),=F'0'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@SOUPD)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         L     2,=F'-1'
         CLR   8,2
         BNE   @@L7
         MVC   108(4,13),=F'0'
         MVC   132(4,13),=F'2'
         ST    9,88(13)
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
* Function *@@75ACCE epilogue
         PDPEPIL
* Function *@@75ACCE literal pool
         DS    0F
         LTORG
* Function *@@75ACCE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
