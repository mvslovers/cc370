         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_stop'
* Program text area
@V1      EQU   *
         DC    C'tmr_stop'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s QUIESCE posted'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s SHUTDOWN posted'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s thread DELETE'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s thread DETACH'
         DC    X'0'
@@LC4    EQU   *
         DC    C'%s timer thread did not stop, TCB(%06X) retained'
         DC    X'0'
         DS    0F
* X-func *@@TMSTOP prologue
@@TMSTOP PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMSTOP code
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    4,15
         L     15,=F'-1'
         LTR   4,4
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     2,12(4)
         LTR   2,2
         BE    @@L3
         IC    2,8(4)
         N     2,=F'64'
         LTR   2,2
         BE    @@L3
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         OI    8(4),32
         A     4,=F'20'
         ST    4,88(13)
         A     4,=F'-20'
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ECBPST)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L4
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     2,12(4)
         LTR   2,2
         BE    @@L5
         IC    2,8(4)
         N     2,=F'64'
         LTR   2,2
         BE    @@L5
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         OI    8(4),16
         A     4,=F'20'
         ST    4,88(13)
         A     4,=F'-20'
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ECBPST)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L6
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         SLR   5,5
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     15,12(4)
         LTR   15,15
         BE    @@L7
         IC    2,8(4)
         N     2,=F'16'
         LTR   2,2
         BE    @@L7
         LR    5,15
@@L7     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L8
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L9
         L     15,16(5)
         N     15,=F'1073741824'
         LTR   15,15
         BNE   @@L9
         ST    15,112(13)
         A     5,=F'16'
         ST    5,104(13)
         LA    3,112(,13)
         LR    2,3
         O     2,=F'-2147483648'
         ST    2,108(13)
         LA    2,104(,13)
         ST    2,88(13)
         ST    3,92(13)
         MVC   96(4,13),=F'500'
         ST    15,100(13)
         LA    1,88(,13)
         L     15,=V(@@ECBTWL)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     2,12(4)
         LTR   2,2
         BE    @@L10
         IC    2,8(4)
         N     2,=F'16'
         LTR   2,2
         BE    @@L10
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         A     4,=F'12'
         ST    4,88(13)
         A     4,=F'-12'
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
@@L10    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L11
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     2,12(4)
         LTR   2,2
         BE    @@L12
         IC    2,8(4)
         N     2,=F'16'
         LTR   2,2
         BNE   @@L12
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),12(4)
         LA    1,88(,13)
         L     15,=V(@@CTDET)
         BALR  14,15
         L     5,=F'-1'
         CLR   15,5
         BNE   @@L13
         MVC   88(4,13),=A(@@LC4)
         MVC   92(4,13),=A(@V1)
         L     2,12(4)
         MVC   96(4,13),8(2)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L12
@@L13    EQU   *
         L     12,0(,10)
         ST    2,12(4)
@@L12    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L16
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L16    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@TMSTOP epilogue
         PDPEPIL
* Function *@@TMSTOP literal pool
         DS    0F
         LTORG
* Function *@@TMSTOP page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
