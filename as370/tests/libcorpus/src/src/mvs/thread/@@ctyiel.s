         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_yield'
* Program text area
         DS    0F
* X-func *@@CTYIEL prologue
@@CTYIEL PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTYIEL code
         SLR   3,3
         ST    3,104(13)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'1'
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@ECBTW)
         BALR  14,15
         LR    15,3
* Function *@@CTYIEL epilogue
         PDPEPIL
* Function *@@CTYIEL literal pool
         DS    0F
         LTORG
* Function *@@CTYIEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
