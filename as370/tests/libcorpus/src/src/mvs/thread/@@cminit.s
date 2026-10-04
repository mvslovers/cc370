         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_manager_init'
* Program text area
@@LC0    EQU   *
         DC    C'CTHDMGR'
         DC    X'0'
@@LC1    EQU   *
         DC    C'CTHDMGR.%04X.%08X'
         DC    X'0'
         DS    0F
* X-func *@@CMINIT prologue
@@CMINIT PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMINIT code
         L     4,0(11)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'88'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,104(13)
         SLR   3,3
         L     2,548(3)
         LH    5,36(2)
         N     5,=XL4'0000FFFF'
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         MVC   0(8,15),0(2)
         MVC   16(4,15),4(11)
         MVC   20(4,15),8(11)
         ST    3,36(15)
         MVC   24(4,15),12(11)
         LA    2,3(0,0)
         LA    6,5(0,0)
         CLR   4,6
         BH    @@L5
         LR    2,3
         LA    3,3(0,0)
         CLR   4,3
         BNH   @@L5
         LA    2,1(0,0)
@@L5     EQU   *
         L     12,0(,10)
         ST    2,40(15)
         L     2,104(13)
         ST    4,44(2)
         L     2,104(13)
         A     2,=F'60'
         ST    2,88(13)
         A     2,=F'-60'
         MVC   92(4,13),=A(@@LC1)
         ST    5,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         L     2,104(13)
         MVC   88(4,13),=A(@@F6)
         ST    2,92(13)
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=F'32768'
         LA    1,88(,13)
         L     15,=V(@@CTCRTX)
         BALR  14,15
         ST    15,8(2)
         L     2,104(13)
         L     2,8(2)
         LTR   2,2
         BNE   @@L3
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMTERM)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function *@@CMINIT epilogue
         PDPEPIL
* Function *@@CMINIT literal pool
         DS    0F
         LTORG
* Function *@@CMINIT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'dispatch_thread'
         DS    0F
* Function dispatch_thread,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function dispatch_thread code
         L     2,0(11)
         LA    4,1(0,0)
         SLR   5,5
         LR    3,4
         LR    6,5
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
@@L9     EQU   *
         ST    2,88(13)
         ST    6,92(13)
         ST    5,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         LA    3,3(0,0)
         CLR   15,3
         BE    @@L10
         LA    3,2(0,0)
         CLR   15,3
         BNE   @@L13
         LA    6,1(0,0)
@@L13    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
         LR    3,15
         LTR   6,6
         BE    @@L15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F10)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L11
         B     @@L10
@@L15    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=A(@@F11)
         BALR  14,15
         LR    5,15
@@L11    EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L9
@@L10    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=A(@@F12)
         BALR  14,15
@@L18    EQU   *
         SLR   15,15
* Function dispatch_thread epilogue
         PDPEPIL
* Function dispatch_thread literal pool
         DS    0F
         LTORG
* Function dispatch_thread page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'dispatch_thread_init'
         DS    0F
* Function dispatch_thread_init,F7 prologue
@@F7     PDPPRLG CINDEX=2,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function dispatch_thread_init code
         L     2,0(11)
         MVC   96(4,13),=F'0'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   36(4,2),=F'1'
         A     2,=F'28'
         ST    2,88(13)
         A     2,=F'-28'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         ST    15,96(13)
         L     3,96(13)
@@L26    EQU   *
         CL    3,40(2)
         BNL   @@L25
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWADD)
         BALR  14,15
         A     3,=F'1'
         B     @@L26
@@L25    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         SLR   15,15
* Function dispatch_thread_init epilogue
         PDPEPIL
* Function dispatch_thread_init literal pool
         DS    0F
         LTORG
* Function dispatch_thread_init page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC 'dispatch_thread_timed_wait'
         DS    0F
* Function dispatch_thread_timed_wait,F8 prologue
@@F8     PDPPRLG CINDEX=3,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function dispatch_thread_timed_wait code
         L     3,0(11)
         SLR   6,6
         LA    7,10(0,0)
         L     2,4(11)
         LTR   2,2
         BNE   @@L29
         L     2,8(11)
         LTR   2,2
         BE    @@L30
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    5,3
         A     5,=F'28'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L41    EQU   *
         LTR   4,4
         BE    @@L32
         ST    5,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         LTR   15,15
         BE    @@L33
         L     2,24(15)
         LTR   2,2
         BE    @@L36
         L     2,24(15)
         LA    8,2(0,0)
         CLR   2,8
         BNE   @@L33
@@L36    EQU   *
         L     12,0(,10)
         LA    6,1(0,0)
         B     @@L32
@@L33    EQU   *
         L     12,0(,10)
         BCTR  4,0
         B     @@L41
@@L32    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LTR   6,6
         BNE   @@L29
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=A(@@F13)
         BALR  14,15
         B     @@L29
@@L30    EQU   *
         L     12,0(,10)
         LA    7,100(0,0)
         L     2,12(11)
         LTR   2,2
         BNE   @@L29
         LA    7,1000(0,0)
@@L29    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   36(4,3),=F'4'
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         A     3,=F'12'
         ST    3,88(13)
         A     3,=F'-12'
         ST    7,92(13)
         MVC   96(4,13),=F'4'
         LA    1,88(,13)
         L     15,=V(@@CTTWAT)
         BALR  14,15
         LR    6,15
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   36(4,3),=F'1'
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,6
* Function dispatch_thread_timed_wait epilogue
         PDPEPIL
* Function dispatch_thread_timed_wait literal pool
         DS    0F
         LTORG
* Function dispatch_thread_timed_wait page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC 'dispatch_thread_check'
@@LC2    EQU   *
         DC    C'worker %08X, task %08X ended ABEND S%03X'
         DC    X'0'
         DS    0F
* Function dispatch_thread_check,F9 prologue
@@F9     PDPPRLG CINDEX=4,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function dispatch_thread_check code
         L     6,0(11)
         SLR   8,8
         ST    6,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         A     6,=F'28'
         ST    6,88(13)
         A     6,=F'-28'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    7,8
         CLR   8,15
         BNL   @@L44
@@L51    EQU   *
         L     3,28(6)
         LR    2,7
         SLL   2,2
         L     4,0(2,3)
         ST    4,108(13)
         LTR   4,4
         BE    @@L45
         L     5,16(4)
         ST    5,104(13)
         LTR   5,5
         BE    @@L45
         L     2,28(4)
         N     2,=F'1'
         LTR   2,2
         BE    @@L48
         LA    8,1(0,0)
@@L48    EQU   *
         L     12,0(,10)
         L     3,16(5)
         LR    2,3
         N     2,=F'1073741824'
         LTR   2,2
         BE    @@L45
         LR    2,3
         SRL   2,12
         N     2,=F'4095'
         LTR   2,2
         BE    @@L50
         MVC   88(4,13),=A(@@LC2)
         ST    4,92(13)
         ST    5,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L50    EQU   *
         L     12,0(,10)
         L     2,108(13)
         MVC   24(4,2),=F'5'
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
         L     2,108(13)
         MVC   16(4,2),=F'0'
         LA    2,108(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWDEL)
         BALR  14,15
         LA    8,1(0,0)
         B     @@L44
@@L45    EQU   *
         L     12,0(,10)
         A     7,=F'1'
         CLR   7,15
         BL    @@L51
@@L44    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,8
* Function dispatch_thread_check epilogue
         PDPEPIL
* Function dispatch_thread_check literal pool
         DS    0F
         LTORG
* Function dispatch_thread_check page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         
&FUNC    SETC 'dispatch_thread_quiesce'
         DS    0F
* Function dispatch_thread_quiesce,F10 prologue
@@F10    PDPPRLG CINDEX=5,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function dispatch_thread_quiesce code
         L     6,0(11)
         LA    8,1(0,0)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    2,15
         LR    7,6
         A     7,=F'28'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         LTR   2,2
         BNE   @@L54
         ST    6,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L54    EQU   *
         L     12,0(,10)
         LR    4,5
         LTR   5,5
         BE    @@L66
@@L63    EQU   *
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    2,15
         ST    7,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         LR    3,15
         LTR   2,2
         BNE   @@L58
         ST    6,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L58    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L57
         L     2,16(3)
         LTR   2,2
         BE    @@L57
         L     2,16(2)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L57
         L     2,24(3)
         LA    9,2(0,0)
         CLR   2,9
         BNE   @@L57
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWSHU)
         BALR  14,15
@@L57    EQU   *
         L     12,0(,10)
         BCTR  4,0
         LTR   4,4
         BNE   @@L63
@@L66    EQU   *
         L     12,0(,10)
         LTR   5,5
         BNE   @@L64
         LR    8,5
@@L64    EQU   *
         L     12,0(,10)
         LR    15,8
* Function dispatch_thread_quiesce epilogue
         PDPEPIL
* Function dispatch_thread_quiesce literal pool
         DS    0F
         LTORG
* Function dispatch_thread_quiesce page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         
&FUNC    SETC 'dispatch_work'
         DS    0F
* Function dispatch_work,F14 prologue
@@F14    PDPPRLG CINDEX=6,FRAME=120,BASER=12,ENTRY=NO
         B     @@FEN6
         LTORG
@@FEN6   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG6    EQU   *
         LR    11,1
         L     10,=A(@@PGT6)
* Function dispatch_work code
         L     7,0(11)
         L     3,4(11)
         LTR   3,3
         BE    @@L67
         L     2,16(3)
         LTR   2,2
         BE    @@L67
         L     5,16(2)
         N     5,=F'1073741824'
         LTR   5,5
         BNE   @@L67
         L     2,24(3)
         LA    4,2(0,0)
         CLR   2,4
         BNE   @@L67
         LR    6,7
         A     6,=F'32'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
         L     15,28(3)
         LR    2,15
         N     2,=F'2'
         LTR   2,2
         BE    @@L73
         LR    4,5
         N     15,=F'1'
         LTR   15,15
         BNE   @@L75
         B     @@L67
@@L73    EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L75
         N     15,=F'1'
         LTR   15,15
         BE    @@L67
@@L75    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         LA    0,104(,13)
         LR    2,0
         LA    1,88(,13)
         L     15,=V(TM64TIME)
         BALR  14,15
         ST    2,88(13)
         A     3,=F'40'
         ST    3,92(13)
         A     3,=F'-40'
         LA    2,112(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SUB)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64TI32)
         BALR  14,15
         LR    5,15
         LTR   4,4
         BNE   @@L79
         LTR   15,15
         BE    @@L80
@@L79    EQU   *
         L     12,0(,10)
         LR    2,7
         A     2,=F'48'
         ST    2,88(13)
         MVC   92(4,13),=F'1'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AU32)
         BALR  14,15
         LR    2,3
         A     2,=F'56'
         ST    2,88(13)
         MVC   92(4,13),=F'1'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AU32)
         BALR  14,15
         MVC   48(8,3),104(13)
         MVC   24(4,3),=F'3'
         LTR   4,4
         BE    @@L80
         ST    6,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         ST    15,20(3)
         A     3,=F'8'
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         B     @@L83
@@L80    EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L67
         MVC   20(4,3),=F'0'
         A     3,=F'8'
         ST    3,88(13)
         MVC   92(4,13),=F'1'
@@L83    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
@@L69    EQU   *
@@L67    EQU   *
         L     12,0(,10)
* Function dispatch_work epilogue
         PDPEPIL
* Function dispatch_work literal pool
         DS    0F
         LTORG
* Function dispatch_work page table
         DS    0F
@@PGT6   EQU   *
         DC    A(@@PG6)
         
&FUNC    SETC 'dispatch_thread_work'
         DS    0F
* Function dispatch_thread_work,F11 prologue
@@F11    PDPPRLG CINDEX=7,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN7
         LTORG
@@FEN7   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG7    EQU   *
         LR    11,1
         L     10,=A(@@PGT7)
* Function dispatch_thread_work code
         L     4,0(11)
         SLR   7,7
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,4
         A     3,=F'28'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
         CL    15,40(4)
         BNL   @@L85
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWADD)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
@@L85    EQU   *
         L     12,0(,10)
         CL    6,44(4)
         BNH   @@L86
         LR    5,6
@@L114   EQU   *
         LTR   5,5
         BE    @@L86
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         ST    15,96(13)
         LTR   15,15
         BE    @@L89
         L     2,24(15)
         LA    8,2(0,0)
         CLR   2,8
         BNE   @@L89
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWSHU)
         BALR  14,15
         LTR   15,15
         BNE   @@L89
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWDEL)
         BALR  14,15
         BCTR  6,0
         CL    6,44(4)
         BNH   @@L86
@@L89    EQU   *
         L     12,0(,10)
         BCTR  5,0
         B     @@L114
@@L86    EQU   *
         L     12,0(,10)
         L     2,4(11)
         LTR   2,2
         BNE   @@L95
         A     4,=F'32'
         ST    4,88(13)
         A     4,=F'-32'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L97
@@L95    EQU   *
         L     12,0(,10)
         A     4,=F'28'
         ST    4,88(13)
         A     4,=F'-28'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L97
         L     2,56(4)
         A     2,=F'1'
         ST    2,56(4)
         CLR   2,15
         BL    @@L99
         MVC   56(4,4),=F'0'
@@L99    EQU   *
         L     12,0(,10)
         L     5,56(4)
@@L115   EQU   *
         CLR   5,6
         BNL   @@L111
         ST    4,88(13)
         L     3,28(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=A(@@F14)
         BALR  14,15
         A     5,=F'1'
         B     @@L115
@@L111   EQU   *
         L     12,0(,10)
         SLR   5,5
@@L116   EQU   *
         CL    5,56(4)
         BNL   @@L113
         ST    4,88(13)
         L     3,28(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=A(@@F14)
         BALR  14,15
         A     5,=F'1'
         B     @@L116
@@L113   EQU   *
         L     12,0(,10)
         A     4,=F'32'
         ST    4,88(13)
         A     4,=F'-32'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L97
         LA    7,1(0,0)
@@L97    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         LR    15,7
* Function dispatch_thread_work epilogue
         PDPEPIL
* Function dispatch_thread_work literal pool
         DS    0F
         LTORG
* Function dispatch_thread_work page table
         DS    0F
@@PGT7   EQU   *
         DC    A(@@PG7)
         
&FUNC    SETC 'dispatch_thread_create'
         DS    0F
* Function dispatch_thread_create,F13 prologue
@@F13    PDPPRLG CINDEX=8,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN8
         LTORG
@@FEN8   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG8    EQU   *
         LR    11,1
         L     10,=A(@@PGT8)
* Function dispatch_thread_create code
         L     2,0(11)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         A     2,=F'28'
         ST    2,88(13)
         A     2,=F'-28'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         CL    15,44(2)
         BNL   @@L118
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWADD)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@CTYIEL)
         BALR  14,15
@@L118   EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         SLR   15,15
* Function dispatch_thread_create epilogue
         PDPEPIL
* Function dispatch_thread_create literal pool
         DS    0F
         LTORG
* Function dispatch_thread_create page table
         DS    0F
@@PGT8   EQU   *
         DC    A(@@PG8)
         
&FUNC    SETC 'dispatch_thread_term'
         DS    0F
* Function dispatch_thread_term,F12 prologue
@@F12    PDPPRLG CINDEX=9,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN9
         LTORG
@@FEN9   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG9    EQU   *
         LR    11,1
         L     10,=A(@@PGT9)
* Function dispatch_thread_term code
         L     4,0(11)
         SLR   3,3
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   36(4,4),=F'2'
         LTR   15,15
         BNE   @@L120
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L120   EQU   *
         L     12,0(,10)
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    2,15
         LR    5,4
         A     5,=F'28'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    3,15
         LTR   2,2
         BNE   @@L121
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L121   EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L131
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    2,15
         ST    5,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         ST    15,96(13)
         LTR   2,2
         BNE   @@L125
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L125   EQU   *
         L     12,0(,10)
         L     2,96(13)
         LTR   2,2
         BE    @@L124
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWSHU)
         BALR  14,15
         LTR   15,15
         BNE   @@L124
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWDEL)
         BALR  14,15
@@L124   EQU   *
         L     12,0(,10)
         BCTR  3,0
         B     @@L121
@@L131   EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   36(4,4),=F'3'
         LTR   15,15
         BNE   @@L129
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L129   EQU   *
         L     12,0(,10)
         SLR   15,15
* Function dispatch_thread_term epilogue
         PDPEPIL
* Function dispatch_thread_term literal pool
         DS    0F
         LTORG
* Function dispatch_thread_term page table
         DS    0F
@@PGT9   EQU   *
         DC    A(@@PG9)
         END
