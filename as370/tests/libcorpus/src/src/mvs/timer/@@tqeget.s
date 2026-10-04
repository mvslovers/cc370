         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tqe_get'
* Program text area
         DS    0F
* X-func *@@TQEGET prologue
@@TQEGET PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TQEGET code
         L     8,0(11)
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    4,15
         SLR   6,6
         LA    1,88(,13)
         L     15,=V(@@TMINIT)
         BALR  14,15
         ST    4,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    7,15
         A     4,=F'24'
         ST    4,88(13)
         A     4,=F'-24'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,6
         CLR   6,15
         BNL   @@L3
@@L7     EQU   *
         L     3,24(4)
         LR    2,5
         SLL   2,2
         L     3,0(2,3)
         LTR   3,3
         BE    @@L4
         L     2,40(3)
         CLR   2,8
         BNE   @@L4
         LR    6,3
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         CLR   5,15
         BL    @@L7
@@L3     EQU   *
         L     12,0(,10)
         LTR   7,7
         BNE   @@L8
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LR    15,6
* Function *@@TQEGET epilogue
         PDPEPIL
* Function *@@TQEGET literal pool
         DS    0F
         LTORG
* Function *@@TQEGET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
