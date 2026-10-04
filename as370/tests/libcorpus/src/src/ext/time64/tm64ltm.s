         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'gmtime64'
* Program text area
         DS    0F
* X-func *TM64LTM prologue
TM64LTM  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64LTM code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         A     15,=F'296'
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(TM64LTMR)
         BALR  14,15
* Function *TM64LTM epilogue
         PDPEPIL
* Function *TM64LTM literal pool
         DS    0F
         LTORG
* Function *TM64LTM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
