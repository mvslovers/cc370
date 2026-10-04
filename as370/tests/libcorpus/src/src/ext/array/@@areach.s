         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arrayeach'
* Program text area
         DS    0F
* X-func *@@AREACH prologue
@@AREACH PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@AREACH code
         L     6,0(11)
         L     8,4(11)
         L     7,8(11)
         SLR   2,2
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         LR    4,2
         CLR   2,15
         BNL   @@L3
@@L6     EQU   *
         ST    4,88(13)
         L     3,0(6)
         LR    2,4
         SLL   2,2
         L     3,0(2,3)
         ST    3,92(13)
         ST    7,96(13)
         LA    1,88(,13)
         LA    15,0(8)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L3
         A     4,=F'1'
         CLR   4,5
         BL    @@L6
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@AREACH epilogue
         PDPEPIL
* Function *@@AREACH literal pool
         DS    0F
         LTORG
* Function *@@AREACH page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
