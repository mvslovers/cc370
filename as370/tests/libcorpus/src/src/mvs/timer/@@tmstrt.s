         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_start'
* Program text area
@V1      EQU   *
         DC    C'tmr_start'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s unable to create timer thread'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s waiting for timer thread to start'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s timer thread failed to start'
         DC    X'0'
         DS    0F
* X-func *@@TMSTRT prologue
@@TMSTRT PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMSTRT code
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    3,15
         SLR   6,6
         LR    5,6
         LA    15,12(0,0)
         LTR   3,3
         BE    @@L1
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    4,15
         L     2,12(3)
         LTR   2,2
         BNE   @@L3
         MVC   88(4,13),=V(@@TMTHRD)
         ST    3,92(13)
         ST    6,96(13)
         MVC   100(4,13),=F'32768'
         LA    1,88(,13)
         L     15,=V(@@CTCRTX)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNE   @@L4
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LA    6,12(0,0)
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         ST    15,12(3)
         LTR   4,4
         BNE   @@L6
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@CTYIEL)
         BALR  14,15
         B     @@L21
@@L3     EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L7
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNE   @@L9
@@L21    EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L9
         SLR   5,5
@@L17    EQU   *
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         IC    2,8(3)
         N     2,=F'64'
         LTR   15,15
         BNE   @@L14
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         LTR   2,2
         BNE   @@L12
         LR    2,5
         N     2,=F'3'
         LA    4,3(0,0)
         CLR   2,4
         BNE   @@L16
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L16    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@CTYIEL)
         BALR  14,15
         A     5,=F'1'
         LA    2,99(0,0)
         CR    5,2
         BNH   @@L17
@@L12    EQU   *
         L     12,0(,10)
         LA    4,100(0,0)
         CLR   5,4
         BNE   @@L9
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    4,15
         A     3,=F'12'
         ST    3,88(13)
         A     3,=F'-12'
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
         NI    8(3),191
         LTR   4,4
         BNE   @@L19
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L19    EQU   *
         L     12,0(,10)
         LA    6,12(0,0)
@@L9     EQU   *
         L     12,0(,10)
         LR    15,6
@@L1     EQU   *
         L     12,0(,10)
* Function *@@TMSTRT epilogue
         PDPEPIL
* Function *@@TMSTRT literal pool
         DS    0F
         LTORG
* Function *@@TMSTRT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
