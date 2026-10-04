         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ctime64_r'
* Program text area
         DS    0F
* X-func *TM64CTIR prologue
TM64CTIR PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64CTIR code
         L     3,4(11)
         LTR   3,3
         BE    @@L2
         MVC   88(4,13),0(11)
         LA    2,96(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(TM64LTMR)
         BALR  14,15
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(TM64ASCR)
         BALR  14,15
         LR    3,15
@@L2     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *TM64CTIR epilogue
         PDPEPIL
* Function *TM64CTIR literal pool
         DS    0F
         LTORG
* Function *TM64CTIR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
