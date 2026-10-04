         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_get_tcb'
* Program text area
         DS    0F
* X-func *@@CTGTCB prologue
@@CTGTCB PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTGTCB code
         L     15,0(11)
         LTR   15,15
         BE    @@L2
         L     15,8(15)
         B     @@L4
@@L2     EQU   *
         L     12,0(,10)
         L     15,540(15)
@@L4     EQU   *
         L     12,0(,10)
* Function *@@CTGTCB epilogue
         PDPEPIL
* Function *@@CTGTCB literal pool
         DS    0F
         LTORG
* Function *@@CTGTCB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
