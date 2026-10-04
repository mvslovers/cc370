         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'clib_auth_cde'
* Program text area
         DS    0F
* X-func *@@AUTCDE prologue
@@AUTCDE PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@AUTCDE code
         L     2,0(11)
         LTR   2,2
         BE    @@L2
         MODESET KEY=ZERO,MODE=SUP

         OI    29(2),3
         MODESET KEY=NZERO,MODE=PROB
@@L2     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function *@@AUTCDE epilogue
         PDPEPIL
* Function *@@AUTCDE literal pool
         DS    0F
         LTORG
* Function *@@AUTCDE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
