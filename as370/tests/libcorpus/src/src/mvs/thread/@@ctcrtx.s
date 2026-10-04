         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_create_ex'
* Program text area
         DS    0F
* X-func *@@CTCRTX prologue
@@CTCRTX PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTCRTX code
         L     3,0(11)
         L     2,12(11)
         SLR   5,5
         L     4,540(5)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTFIND)
         BALR  14,15
         ST    5,104(13)
         LTR   2,2
         BNE   @@L2
         L     2,=F'65536'
@@L2     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L3
         L     3,=A(@@F6)
@@L3     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L4
         ST    4,88(13)
         ST    15,92(13)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   15,15
         BE    @@L6
@@L4     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),8(15)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         ST    15,104(13)
         LTR   15,15
         BE    @@L6
         ST    3,28(15)
         L     2,104(13)
         MVC   32(4,2),4(11)
         L     2,104(13)
         MVC   36(4,2),8(11)
         MVC   88(4,13),=A(@@F8)
         MVC   92(4,13),104(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         LTR   15,15
         BNE   @@L8
         L     2,104(13)
         L     15,20(2)
@@L8     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L6
         L     2,104(13)
         ST    5,8(2)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function *@@CTCRTX epilogue
         PDPEPIL
* Function *@@CTCRTX literal pool
         DS    0F
         LTORG
* Function *@@CTCRTX page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'attach'
         DS    0F
* Function attach,F8 prologue
@@F8     PDPPRLG CINDEX=1,FRAME=152,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function attach code
         L     4,0(11)
         LA    6,88(,13)
         LA    7,64(0,0)
         SLR   2,2
         LR    3,2
         MVCL  6,2
         LR    3,4
         A     3,=F'16'
         LA    2,88(,13)
         LA    1,0(,4)
         ATTACH EP=CTHREAD,ECB=(3),DPMOD=-1,SF=(E,(2))
         ST    1,8(4)
         ST    15,20(4)
         L     15,20(4)
* Function attach epilogue
         PDPEPIL
* Function attach literal pool
         DS    0F
         LTORG
* Function attach page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'newthread'
@@LC0    EQU   *
         DC    C'CTHDTASK'
         DC    X'0'
         DS    0F
* Function newthread,F7 prologue
@@F7     PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function newthread code
         L     3,8(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    5,15
         LR    2,3
         BCTR  2,0
         LA    4,80(0,0)
         LA    6,78(0,0)
         CLR   2,6
         BNH   @@L13
         LR    4,3
         A     4,=F'7'
         N     4,=F'1048568'
@@L13    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         A     4,=F'44'
         ST    4,92(13)
         A     4,=F'-44'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    3,15
         LTR   5,5
         BNE   @@L14
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LR    15,5
         B     @@L11
@@L14    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L15
         L     2,=A(@@LC0)
         MVC   0(9,15),0(2)
         MVC   8(4,15),0(11)
         MVC   12(4,15),4(11)
         ST    4,24(15)
         LR    2,5
         A     2,=F'64'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L16
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   15,15
         B     @@L11
@@L16    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L15    EQU   *
         L     12,0(,10)
         LR    15,3
@@L11    EQU   *
         L     12,0(,10)
* Function newthread epilogue
         PDPEPIL
* Function newthread literal pool
         DS    0F
         LTORG
* Function newthread page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC 'dummy'
@@LC1    EQU   *
         DC    C'dummy(arg1=%08X, arg2=%08X)'
         DC    X'15'
         DC    X'0'
@@LC2    EQU   *
         DC    C'CTHDTASK handle=%08X'
         DC    X'15'
         DC    X'0'
@@LC3    EQU   *
         DC    C'task->eye         %-8.8s'
         DC    X'15'
         DC    X'0'
@@LC4    EQU   *
         DC    C'task->tcb         %08X'
         DC    X'15'
         DC    X'0'
@@LC5    EQU   *
         DC    C'task->owntcb      %08X'
         DC    X'15'
         DC    X'0'
@@LC6    EQU   *
         DC    C'task->termecb     %08X'
         DC    X'15'
         DC    X'0'
@@LC7    EQU   *
         DC    C'task->rc          %08X (%d)'
         DC    X'15'
         DC    X'0'
@@LC8    EQU   *
         DC    C'task->stacksize   %08X (%d)'
         DC    X'15'
         DC    X'0'
@@LC9    EQU   *
         DC    C'task->func        %08X'
         DC    X'15'
         DC    X'0'
@@LC10   EQU   *
         DC    C'task->arg1        %08X'
         DC    X'15'
         DC    X'0'
@@LC11   EQU   *
         DC    C'task->arg2        %08X'
         DC    X'15'
         DC    X'0'
         DS    0F
* Function dummy,F6 prologue
@@F6     PDPPRLG CINDEX=3,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function dummy code
         LA    1,88(,13)
         L     15,=V(@@CTSELF)
         BALR  14,15
         LR    2,15
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),0(11)
         MVC   96(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC2)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LTR   2,2
         BE    @@L18
         MVC   88(4,13),=A(@@LC3)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC4)
         MVC   92(4,13),8(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC5)
         MVC   92(4,13),12(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC6)
         MVC   92(4,13),16(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC7)
         MVC   92(4,13),20(2)
         MVC   96(4,13),20(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC8)
         MVC   92(4,13),24(2)
         MVC   96(4,13),24(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC9)
         MVC   92(4,13),28(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC10)
         MVC   92(4,13),32(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC11)
         MVC   92(4,13),36(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L18    EQU   *
         L     12,0(,10)
         L     15,=F'-1'
* Function dummy epilogue
         PDPEPIL
* Function dummy literal pool
         DS    0F
         LTORG
* Function dummy page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC 'cleanup_thread'
         DS    0F
* Function cleanup_thread,F9 prologue
@@F9     PDPPRLG CINDEX=4,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function cleanup_thread code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L19
         L     2,332(15)
         LTR   2,2
         BE    @@L22
         LR    4,15
         A     4,=F'332'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    2,15
@@L35    EQU   *
         LTR   2,2
         BE    @@L32
         MVC   88(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@CTPOP)
         BALR  14,15
         BCTR  2,0
         B     @@L35
@@L32    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         A     3,=F'336'
         ST    3,88(13)
         A     3,=F'-336'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L22    EQU   *
         L     12,0(,10)
         L     2,340(3)
         LTR   2,2
         BE    @@L19
         LR    4,3
         A     4,=F'340'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    2,15
@@L36    EQU   *
         LTR   2,2
         BE    @@L34
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         LTR   15,15
         BE    @@L29
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(MTXCLUP)
         BALR  14,15
@@L29    EQU   *
         L     12,0(,10)
         BCTR  2,0
         B     @@L36
@@L34    EQU   *
         L     12,0(,10)
         A     3,=F'340'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L21    EQU   *
@@L19    EQU   *
         L     12,0(,10)
* Function cleanup_thread epilogue
         PDPEPIL
* Function cleanup_thread literal pool
         DS    0F
         LTORG
* Function cleanup_thread page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         DS    0F
* X-func __ctclup prologue
@@CTCLUP PDPPRLG CINDEX=5,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function __ctclup code
         MVC   88(4,13),=A(@@F9)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
* Function __ctclup epilogue
         PDPEPIL
* Function __ctclup literal pool
         DS    0F
         LTORG
* Function __ctclup page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         END
