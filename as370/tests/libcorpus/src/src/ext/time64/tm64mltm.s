         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *TM64MLTM prologue
TM64MLTM PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64MLTM code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         A     3,=F'296'
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'1000'
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64DU32)
         BALR  14,15
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(TM64LTMR)
         BALR  14,15
* Function *TM64MLTM epilogue
         PDPEPIL
* Function *TM64MLTM literal pool
         DS    0F
         LTORG
* Function *TM64MLTM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
