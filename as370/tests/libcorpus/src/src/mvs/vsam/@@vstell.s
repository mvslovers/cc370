         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vstell prologue
@@VSTELL PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vstell code
         L     4,0(11)
         SLR   2,2
         ST    2,152(13)
         LA    8,88(,13)
         LA    9,64(0,0)
         LR    6,2
         LR    7,2
         MVCL  8,6
         A     4,=F'104'
         LA    3,88(,13)
         LA    2,152(,13)
         SHOWCB RPL=(4),FIELDS=RBA,AREA=(2),LENGTH=4,MF=(G,(3))
@@L2     EQU   *
         L     15,152(13)
* Function __vstell epilogue
         PDPEPIL
* Function __vstell literal pool
         DS    0F
         LTORG
* Function __vstell page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
