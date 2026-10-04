         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBLOCK'
         DC    X'0'
         DS    0F
* X-func __lkrn prologue
@@LKRN   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __lkrn code
         L     3,4(11)
         LPR   2,3
         LCR   2,2
         SRL   2,29
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),0(11)
         N     2,=F'4'
         ST    2,96(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function __lkrn epilogue
         PDPEPIL
* Function __lkrn literal pool
         DS    0F
         LTORG
* Function __lkrn page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
