         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'asctime64'
* Program text area
         DS    0F
* X-func *TM64ASC prologue
TM64ASC  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64ASC code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L4
         A     2,=F'24'
         BE    @@L4
         MVC   88(4,13),0(11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(TM64ASCR)
         BALR  14,15
         LR    2,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *TM64ASC epilogue
         PDPEPIL
* Function *TM64ASC literal pool
         DS    0F
         LTORG
* Function *TM64ASC page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
