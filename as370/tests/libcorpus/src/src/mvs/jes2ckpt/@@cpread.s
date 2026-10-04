         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __cpread prologue
@@CPREAD PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cpread code
         L     2,0(11)
         L     7,4(11)
         L     15,=F'-1'
         LTR   2,2
         BE    @@L2
         L     6,16(2)
         LA    4,88(,13)
         LA    5,16(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         IC    2,48(6)
         N     2,=F'16'
         LTR   2,2
         BE    @@L2
         LA    2,88(,13)
         READ  (2),SF,(6),(7),4096,MF=E READ FIRST RECORD
         CHECK (2)
         SLR   15,15
@@L2     EQU   *
         L     12,0(,10)
* Function __cpread epilogue
         PDPEPIL
* Function __cpread literal pool
         DS    0F
         LTORG
* Function __cpread page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
