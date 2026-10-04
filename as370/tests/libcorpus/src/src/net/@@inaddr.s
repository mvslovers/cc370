         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@INADDR prologue
@@INADDR PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@INADDR code
         MVC   88(4,13),0(11)
         LA    2,96(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@INATON)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BE    @@L3
         L     2,96(13)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@INADDR epilogue
         PDPEPIL
* Function *@@INADDR literal pool
         DS    0F
         LTORG
* Function *@@INADDR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
