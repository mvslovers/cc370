         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBLOCK'
         DC    X'0'
         DS    0F
* X-func __lkuntr prologue
@@LKUNTR PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __lkuntr code
         LA    15,64(0,0)
         L     2,4(11)
         LTR   2,2
         BE    @@L2
         LA    15,68(0,0)
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),0(11)
         ST    15,96(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function __lkuntr epilogue
         PDPEPIL
* Function __lkuntr literal pool
         DS    0F
         LTORG
* Function __lkuntr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
