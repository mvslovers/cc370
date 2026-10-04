         COPY  PDPTOP
         CSECT
         DS    0F
@V1      EQU   *
         DS    XL32
         
&FUNC    SETC 'tmr_get'
* Program text area
         DS    0F
* X-func *@@TMRGET prologue
@@TMRGET PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMRGET code
         MVC   88(4,13),=A(@V1)
         MVC   92(4,13),=F'32'
         LA    1,88(,13)
         L     15,=V(@@WSAGET)
         BALR  14,15
* Function *@@TMRGET epilogue
         PDPEPIL
* Function *@@TMRGET literal pool
         DS    0F
         LTORG
* Function *@@TMRGET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
