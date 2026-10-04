         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesjobfr prologue
JESJOBFR PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesjobfr code
         L     5,0(11)
         SLR   3,3
         ST    3,96(13)
         LTR   5,5
         BE    @@L3
         MVC   96(4,13),0(5)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L10    EQU   *
         CLR   3,4
         BNL   @@L9
         LR    2,3
         SLL   2,2
         A     2,96(13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(JESJOBF1)
         BALR  14,15
         A     3,=F'1'
         B     @@L10
@@L9     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         MVC   0(4,5),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function jesjobfr epilogue
         PDPEPIL
* Function jesjobfr literal pool
         DS    0F
         LTORG
* Function jesjobfr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
