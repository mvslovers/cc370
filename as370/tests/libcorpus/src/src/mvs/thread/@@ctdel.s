         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_delete'
* Program text area
@@LC0    EQU   *
         DC    C'CTHDTASK'
         DC    X'0'
@@LC1    EQU   *
         DC    C'cthread_delete(%08X): TCB(%06X) has not ended, t'
         DC    C'ask and stack retained'
         DC    X'0'
         DS    0F
* X-func *@@CTDEL prologue
@@CTDEL  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTDEL code
         L     7,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    6,15
         LTR   7,7
         BE    @@L1
         L     3,0(7)
         LTR   3,3
         BE    @@L1
         L     2,=A(@@LC0)
         CLC   0(9,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L1
         L     2,8(3)
         LTR   2,2
         BE    @@L6
         L     2,16(3)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L6
         MVC   88(4,13),=A(@@LC1)
         ST    3,92(13)
         MVC   96(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L1
@@L14    EQU   *
         ST    5,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L8
@@L6     EQU   *
         L     12,0(,10)
         LR    5,6
         A     5,=F'64'
         ST    5,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   104(4,13),0(5)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   4,4
@@L15    EQU   *
         CLR   4,15
         BNL   @@L8
         LR    3,4
         SLL   3,2
         L     2,104(13)
         L     2,0(3,2)
         LTR   2,2
         BE    @@L9
         CL    2,0(7)
         BE    @@L14
@@L9     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L15
@@L8     EQU   *
         L     12,0(,10)
         A     6,=F'64'
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         MVC   88(4,13),0(7)
         LA    1,88(,13)
         L     15,=V(@@CTDET)
         BALR  14,15
         MVC   88(4,13),0(7)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,7),=F'0'
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function *@@CTDEL epilogue
         PDPEPIL
* Function *@@CTDEL literal pool
         DS    0F
         LTORG
* Function *@@CTDEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
