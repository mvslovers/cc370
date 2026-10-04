         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_self'
* Program text area
         DS    0F
* X-func *@@CTSELF prologue
@@CTSELF PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTSELF code
         SLR   2,2
         L     2,540(2)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTFIND)
         BALR  14,15
@@L2     EQU   *
* Function *@@CTSELF epilogue
         PDPEPIL
* Function *@@CTSELF literal pool
         DS    0F
         LTORG
* Function *@@CTSELF page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
