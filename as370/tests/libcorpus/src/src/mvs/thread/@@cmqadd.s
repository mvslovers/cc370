         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_queue_add'
* Program text area
@@LC0    EQU   *
         DC    C'CTHDQUE'
         DC    X'0'
         DS    0F
* X-func *@@CMQADD prologue
@@CMQADD PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMQADD code
         L     3,0(11)
         SLR   4,4
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    5,15
         L     2,36(3)
         LA    6,2(0,0)
         CLR   2,6
         BE    @@L5
         L     2,36(3)
         LA    6,3(0,0)
         CLR   2,6
         BE    @@L5
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BNE   @@L7
         L     4,=F'-1'
         B     @@L5
@@L7     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC0)
         MVC   0(8,15),0(2)
         ST    3,8(15)
         MVC   12(4,15),4(11)
         A     3,=F'32'
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         A     3,=F'-20'
         ST    3,88(13)
         A     3,=F'-12'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         LR    4,15
@@L5     EQU   *
         L     12,0(,10)
         LTR   5,5
         BNE   @@L3
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function *@@CMQADD epilogue
         PDPEPIL
* Function *@@CMQADD literal pool
         DS    0F
         LTORG
* Function *@@CMQADD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
