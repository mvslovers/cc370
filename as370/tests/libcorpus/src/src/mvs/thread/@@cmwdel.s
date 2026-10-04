         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_worker_del'
* Program text area
@@LC0    EQU   *
         DC    C'cthread_worker_del(%08X): TCB(%06X) has not ende'
         DC    C'd, worker and task storage retained'
         DC    X'0'
         DS    0F
* X-func *@@CMWDEL prologue
@@CMWDEL PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMWDEL code
         L     6,0(11)
         SLR   9,9
         LTR   6,6
         BE    @@L3
         L     4,0(6)
         LTR   4,4
         BE    @@L3
         L     3,16(4)
         ST    3,104(13)
         LTR   3,3
         BE    @@L5
         L     2,8(3)
         LTR   2,2
         BE    @@L5
         L     2,16(3)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L5
         MVC   24(4,4),=F'6'
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),0(6)
         L     2,104(13)
         MVC   96(4,13),8(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         L     9,=F'-1'
         B     @@L3
@@L18    EQU   *
         ST    7,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L8
@@L5     EQU   *
         L     12,0(,10)
         L     5,12(4)
         LTR   5,5
         BE    @@L6
         ST    5,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    8,15
         LR    7,5
         A     7,=F'28'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   4,4
@@L19    EQU   *
         CLR   4,15
         BNL   @@L8
         L     3,28(5)
         LR    2,4
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L9
         CL    2,0(6)
         BE    @@L18
@@L9     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L19
@@L8     EQU   *
         L     12,0(,10)
         LTR   8,8
         BNE   @@L6
         ST    5,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         L     3,0(6)
         L     2,8(3)
         LTR   2,2
         BNL   @@L14
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWSHU)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         L     2,0(6)
         L     2,16(2)
         ST    2,104(13)
         LTR   2,2
         BE    @@L15
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
         L     2,0(6)
         MVC   16(4,2),=F'0'
@@L15    EQU   *
         L     12,0(,10)
         L     2,0(6)
         L     2,20(2)
         ST    2,108(13)
         LTR   2,2
         BE    @@L16
         LA    2,108(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMQDEL)
         BALR  14,15
         L     2,0(6)
         MVC   20(4,2),=F'0'
@@L16    EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(6)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,6),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         LR    15,9
* Function *@@CMWDEL epilogue
         PDPEPIL
* Function *@@CMWDEL literal pool
         DS    0F
         LTORG
* Function *@@CMWDEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
