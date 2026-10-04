         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tqe_purge'
* Program text area
         DS    0F
* X-func *@@TQEPRG prologue
@@TQEPRG PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TQEPRG code
         L     9,0(11)
         LA    8,2(0,0)
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    5,15
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    5,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    7,15
         LR    6,5
         A     6,=F'24'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         SLR   4,4
@@L10    EQU   *
         CLR   4,15
         BNL   @@L3
         L     3,24(5)
         LR    2,4
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L4
         L     2,40(3)
         CLR   2,9
         BNE   @@L4
         ST    6,88(13)
         A     4,=F'1'
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         SLR   8,8
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L10
@@L3     EQU   *
         L     12,0(,10)
         LTR   7,7
         BNE   @@L8
         ST    5,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@TQEPRG epilogue
         PDPEPIL
* Function *@@TQEPRG literal pool
         DS    0F
         LTORG
* Function *@@TQEPRG page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
