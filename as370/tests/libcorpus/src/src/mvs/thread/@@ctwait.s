         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_wait'
* Program text area
         DS    0F
* X-func *@@CTWAIT prologue
@@CTWAIT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTWAIT code
         L     2,0(11)
         MVC   88(4,13),=F'0'
         LTR   2,2
         BE    @@L3
         WAIT  ECB=(2)
         
@@CTWAGN DS    0H
         L     0,0(,2)    get ecb value
         LA    1,0         new ecb value
         CS    0,1,0(2)   save new value in ecb
         BNZ   @@CTWAGN       ecb changed, try again
         N     0,=X'3FFFFFFF'
         ST    0,88(13)        return ecb value
@@L3     EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function *@@CTWAIT epilogue
         PDPEPIL
* Function *@@CTWAIT literal pool
         DS    0F
         LTORG
* Function *@@CTWAIT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
