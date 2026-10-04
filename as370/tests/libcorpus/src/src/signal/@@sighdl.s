         COPY  PDPTOP
         CSECT
* Program data area
         DS    0F
@V1      EQU   *
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
         DC    V(@@SIGDFL)
* Program text area
         DS    0F
* X-func __sighdl prologue
@@SIGHDL PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __sighdl code
         MVC   88(4,13),=A(@V1)
         MVC   92(4,13),=F'28'
         LA    1,88(,13)
         L     15,=V(@@WSAGET)
         BALR  14,15
* Function __sighdl epilogue
         PDPEPIL
* Function __sighdl literal pool
         DS    0F
         LTORG
* Function __sighdl page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
