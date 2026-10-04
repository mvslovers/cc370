         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_worker_add'
* Program text area
@@LC0    EQU   *
         DC    C'CTHDWORK'
         DC    X'0'
         DS    0F
* X-func *@@CMWADD prologue
@@CMWADD PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMWADD code
         L     3,0(11)
         L     5,=F'-1'
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    4,15
         L     2,36(3)
         LA    6,2(0,0)
         CLR   2,6
         BE    @@L5
         L     2,36(3)
         LA    6,3(0,0)
         CLR   2,6
         BE    @@L5
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,104(13)
         LTR   15,15
         BE    @@L5
         L     2,=A(@@LC0)
         MVC   0(9,15),0(2)
         ST    3,12(15)
         MVC   24(4,15),=F'0'
         MVC   88(4,13),=F'0'
         LR    0,15
         A     0,=F'32'
         LA    1,88(,13)
         L     15,=V(TM64TIME)
         BALR  14,15
         A     3,=F'28'
         ST    3,88(13)
         A     3,=F'-28'
         MVC   92(4,13),104(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         L     2,104(13)
         MVC   88(4,13),16(3)
         MVC   92(4,13),20(3)
         ST    2,96(13)
         MVC   100(4,13),24(3)
         LA    1,88(,13)
         L     15,=V(@@CTCRTX)
         BALR  14,15
         ST    15,16(2)
         L     2,104(13)
         L     2,16(2)
         LTR   2,2
         BNE   @@L8
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMWDEL)
         BALR  14,15
         B     @@L5
@@L8     EQU   *
         L     12,0(,10)
         SLR   5,5
@@L5     EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L3
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function *@@CMWADD epilogue
         PDPEPIL
* Function *@@CMWADD literal pool
         DS    0F
         LTORG
* Function *@@CMWADD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
