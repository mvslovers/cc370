         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func oscheck prologue
OSCHECK  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function oscheck code
         MVC   88(4,13),=A(@@F1)
         MVC   92(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
* Function oscheck epilogue
         PDPEPIL
* Function oscheck literal pool
         DS    0F
         LTORG
* Function oscheck page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function check,F1 prologue
@@F1     PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function check code
         L     2,0(11)
         LR    1,2
         CHECK (1)
* Function check epilogue
         PDPEPIL
* Function check literal pool
         DS    0F
         LTORG
* Function check page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
