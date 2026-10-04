         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __bldl prologue
@@BLDL   PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __bldl code
         L     3,0(11)
         L     4,4(11)
         LH    2,0(3)
         CLM   2,3,=H'0'
         BNE   @@L2
         MVC   0(2,3),=H'1'
@@L2     EQU   *
         L     12,0(,10)
         LH    2,2(3)
         CLM   2,3,=H'0'
         BNE   @@L3
         MVC   2(2,3),=H'76'
@@L3     EQU   *
         BLDL  (4),(3)
         LR    2,R15
         L     12,0(,10)
         LR    15,2
* Function __bldl epilogue
         PDPEPIL
* Function __bldl literal pool
         DS    0F
         LTORG
* Function __bldl page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
