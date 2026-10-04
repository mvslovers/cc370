         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'clib_auth_name'
* Program text area
         DS    0F
* X-func *@@AUTNAM prologue
@@AUTNAM PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@AUTNAM code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@FNDCDE)
         BALR  14,15
         LA    2,4(0,0)
         LTR   15,15
         BE    @@L3
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@AUTCDE)
         BALR  14,15
         LR    2,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@AUTNAM epilogue
         PDPEPIL
* Function *@@AUTNAM literal pool
         DS    0F
         LTORG
* Function *@@AUTNAM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
