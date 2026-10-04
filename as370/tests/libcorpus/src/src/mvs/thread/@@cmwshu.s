         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_worker_shutdown'
* Program text area
@@LC0    EQU   *
         DC    C'cthread_worker_shutdown(%08X): worker did not st'
         DC    C'op, TCB(%06X) and its stack retained to avoid te'
         DC    C'rminating a live task'
         DC    X'0'
         DS    0F
* X-func *@@CMWSHU prologue
@@CMWSHU PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMWSHU code
         L     5,0(11)
         SLR   7,7
         LTR   5,5
         BE    @@L3
         L     3,16(5)
         LTR   3,3
         BE    @@L4
         L     2,16(3)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L17
@@L4     EQU   *
         L     12,0(,10)
         LR    6,5
         A     6,=F'8'
         ST    6,88(13)
         MVC   92(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         LTR   3,3
         BE    @@L3
         L     2,8(3)
         LTR   2,2
         BE    @@L3
         SLR   4,4
@@L13    EQU   *
         L     2,16(3)
         N     2,=F'1073741824'
         LTR   2,2
         BE    @@L11
@@L17    EQU   *
         L     12,0(,10)
         L     2,8(3)
         LTR   2,2
         BE    @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTDET)
         BALR  14,15
         B     @@L3
@@L11    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         STIMER WAIT,BINTVL==F'10'   0.10 seconds
         A     4,=F'1'
         LA    2,49(0,0)
         CR    4,2
         BNH   @@L13
         MVC   24(4,5),=F'6'
         MVC   88(4,13),=A(@@LC0)
         ST    5,92(13)
         MVC   96(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         L     7,=F'-1'
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function *@@CMWSHU epilogue
         PDPEPIL
* Function *@@CMWSHU literal pool
         DS    0F
         LTORG
* Function *@@CMWSHU page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
