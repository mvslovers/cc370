         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'super_do'
* Program text area
         DS    0F
* X-func *@@SUDO prologue
@@SUDO   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SUDO code
         LA    4,4(,11)
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L2
         MODESET MODE=SUP
         LR    2,15
         LTR   2,2
         BNE   @@L4
@@L2     EQU   *
         L     12,0(,10)
         L     2,0(11)
         LR    15,2          => function to call 
         LR    1,4           => parameter list
         BALR  14,15         call function
         LR    2,15          save return code
         LTR   3,3
         BNE   @@L4
         MODESET MODE=PROB
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@SUDO epilogue
         PDPEPIL
* Function *@@SUDO literal pool
         DS    0F
         LTORG
* Function *@@SUDO page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
