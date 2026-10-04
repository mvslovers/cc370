         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __isauth prologue
@@ISAUTH PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __isauth code
         TESTAUTH FCTN=1,STATE=NO,KEY=NO,RBLEVEL=1
         ST    15,88(13)
         L     2,88(13)
         LPR   15,2
         BCTR  15,0
         SRL   15,31
* Function __isauth epilogue
         PDPEPIL
* Function __isauth literal pool
         DS    0F
         LTORG
* Function __isauth page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
