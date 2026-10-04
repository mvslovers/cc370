         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__issup'
* Program text area
         DS    0F
* X-func __issup prologue
@@ISSUP  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __issup code
         MVC   88(4,13),=F'0'
         LA    2,88(,13)
         TESTAUTH FCTN=0,STATE=YES,KEY=NO,RBLEVEL=1
         ST    15,0(,2)
         L     2,88(13)
         LPR   15,2
         BCTR  15,0
         SRL   15,31
* Function __issup epilogue
         PDPEPIL
* Function __issup literal pool
         DS    0F
         LTORG
* Function __issup page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
