         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_queue_del'
* Program text area
         DS    0F
* X-func *@@CMQDEL prologue
@@CMQDEL PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMQDEL code
         L     7,0(11)
         SLR   2,2
         LTR   7,7
         BE    @@L3
         L     3,0(7)
         LTR   3,3
         BE    @@L3
         L     5,8(3)
         LTR   5,5
         BE    @@L5
         ST    5,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    8,15
         LR    6,5
         A     6,=F'32'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,2
@@L14    EQU   *
         CLR   4,15
         BNL   @@L7
         L     3,32(5)
         LR    2,4
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L8
         CL    2,0(7)
         BNE   @@L8
         ST    6,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L14
@@L7     EQU   *
         L     12,0(,10)
         LTR   8,8
         BNE   @@L5
         ST    5,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(7)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,7),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function *@@CMQDEL epilogue
         PDPEPIL
* Function *@@CMQDEL literal pool
         DS    0F
         LTORG
* Function *@@CMQDEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
