         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_post'
* Program text area
         DS    0F
* X-func *@@CTPOST prologue
@@CTPOST PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTPOST code
         L     2,0(11)
         SLR   15,15
         LTR   2,2
         BE    @@L3
         ST    2,88(13)
         L     2,4(11)
         N     2,=F'1073741823'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ECBPST)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
* Function *@@CTPOST epilogue
         PDPEPIL
* Function *@@CTPOST literal pool
         DS    0F
         LTORG
* Function *@@CTPOST page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
