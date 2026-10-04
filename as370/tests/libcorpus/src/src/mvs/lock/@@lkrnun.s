         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBLOCK'
         DC    X'0'
         DS    0F
* X-func __lkrnun prologue
@@LKRNUN PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __lkrnun code
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),0(11)
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function __lkrnun epilogue
         PDPEPIL
* Function __lkrnun literal pool
         DS    0F
         LTORG
* Function __lkrnun page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
