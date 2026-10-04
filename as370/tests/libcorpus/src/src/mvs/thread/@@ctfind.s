         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_find'
* Program text area
         DS    0F
* X-func *@@CTFIND prologue
@@CTFIND PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTFIND code
         L     9,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         SLR   7,7
         LTR   15,15
         BE    @@L3
         LR    5,15
         A     5,=F'64'
         ST    5,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    8,15
         MVC   96(4,13),0(5)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,7
         CLR   7,15
         BNL   @@L5
         L     4,96(13)
@@L9     EQU   *
         L     3,0(4)
         LTR   3,3
         BE    @@L6
         L     2,8(3)
         CLR   2,9
         BNE   @@L6
         LR    7,3
         B     @@L5
@@L6     EQU   *
         L     12,0(,10)
         A     6,=F'1'
         A     4,=F'4'
         CLR   6,15
         BL    @@L9
@@L5     EQU   *
         L     12,0(,10)
         LTR   8,8
         BNE   @@L3
         ST    5,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function *@@CTFIND epilogue
         PDPEPIL
* Function *@@CTFIND literal pool
         DS    0F
         LTORG
* Function *@@CTFIND page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
