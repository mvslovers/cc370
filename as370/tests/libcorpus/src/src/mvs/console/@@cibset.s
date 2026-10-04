         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __cibset prologue
@@CIBSET PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cibset code
         L     2,0(11)
         SLR   3,3
         LA    1,88(,13)
         L     15,=V(@@GTCOM)
         BALR  14,15
         LTR   2,2
         BE    @@L3
         A     15,=F'4'
         QEDIT ORIGIN=(15),CIBCTR=(2)
         LR    3,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __cibset epilogue
         PDPEPIL
* Function __cibset literal pool
         DS    0F
         LTORG
* Function __cibset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
