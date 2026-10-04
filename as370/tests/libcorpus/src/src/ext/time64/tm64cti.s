         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ctime64'
* Program text area
         DS    0F
* X-func *TM64CTI prologue
TM64CTI  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64CTI code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(TM64LTM)
         BALR  14,15
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(TM64ASC)
         BALR  14,15
* Function *TM64CTI epilogue
         PDPEPIL
* Function *TM64CTI literal pool
         DS    0F
         LTORG
* Function *TM64CTI page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
