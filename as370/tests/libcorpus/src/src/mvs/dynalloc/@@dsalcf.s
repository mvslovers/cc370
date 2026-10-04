         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __dsalcf prologue
@@DSALCF PDPPRLG CINDEX=0,FRAME=616,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __dsalcf code
         LA    15,4(0,0)
         L     2,4(11)
         LTR   2,2
         BE    @@L3
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'512'
         ST    2,96(13)
         LA    2,8(,11)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         MVI   615(13),0
         MVC   88(4,13),0(11)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@DSALC)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
* Function __dsalcf epilogue
         PDPEPIL
* Function __dsalcf literal pool
         DS    0F
         LTORG
* Function __dsalcf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
