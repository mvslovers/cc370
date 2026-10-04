         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __dscbav prologue
@@DSCBAV PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __dscbav code
         LA    3,120(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'5'
         MVC   96(4,13),0(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVI   125(13),0
         LA    2,128(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'6'
         MVC   96(4,13),4(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVI   134(13),0
         MVC   104(4,13),=F'-1065353216'
         ST    3,108(13)
         ST    2,112(13)
         MVC   116(4,13),8(11)
         LA    2,104(,13)
         LR    1,2
         SVC   27    OBTAIN
         LR    2,15
         LR    15,2
* Function __dscbav epilogue
         PDPEPIL
* Function __dscbav literal pool
         DS    0F
         LTORG
* Function __dscbav page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
