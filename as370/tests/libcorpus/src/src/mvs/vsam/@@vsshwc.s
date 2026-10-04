         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __vsshwc prologue
@@VSSHWC PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsshwc code
         L     5,0(11)
         L     4,8(11)
         SLR   2,2
         ST    2,168(13)
         LA    8,104(,13)
         LA    9,16(0,0)
         LR    6,2
         LR    7,2
         MVCL  8,6
         L     2,12(11)
         STH   2,0(4)
         LA    3,120(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'44'
         MVC   96(4,13),4(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         LA    2,104(,13)
         SHOWCAT ACB=(5),AREA=(4),NAME=(3),MF=(B,(2))
         SHOWCAT MF=(E,(2))
         ST    15,168(13)
         L     15,168(13)
* Function __vsshwc epilogue
         PDPEPIL
* Function __vsshwc literal pool
         DS    0F
         LTORG
* Function __vsshwc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
