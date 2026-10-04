         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __isleap prologue
@@ISLEAP PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __isleap code
         SLR   2,2
         SLR   3,3
         LR    4,2
         LR    5,3
         L     6,0(11)
         SLR   15,15
         LR    2,6
         SRDL  2,32
         LA    7,400(0,0)
         DR    2,7
         LTR   2,2
         BE    @@L3
         LR    2,6
         N     2,=F'3'
         LTR   2,2
         BNE   @@L2
         LR    4,6
         SRDL  4,32
         LA    2,100(0,0)
         DR    4,2
         LTR   4,4
         BE    @@L2
@@L3     EQU   *
         L     12,0(,10)
         LA    15,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
* Function __isleap epilogue
         PDPEPIL
* Function __isleap literal pool
         DS    0F
         LTORG
* Function __isleap page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
