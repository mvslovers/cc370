         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *TM64MCTI prologue
TM64MCTI PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64MCTI code
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'1000'
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64DU32)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(TM64LTM)
         BALR  14,15
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(TM64ASC)
         BALR  14,15
* Function *TM64MCTI epilogue
         PDPEPIL
* Function *TM64MCTI literal pool
         DS    0F
         LTORG
* Function *TM64MCTI page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
