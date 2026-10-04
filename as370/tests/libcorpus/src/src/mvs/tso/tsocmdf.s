         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func tsocmdf prologue
TSOCMDF  PDPPRLG CINDEX=0,FRAME=1128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tsocmdf code
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'1024'
         MVC   96(4,13),4(11)
         LA    2,8(,11)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         MVC   88(4,13),0(11)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(TSOCMD)
         BALR  14,15
* Function tsocmdf epilogue
         PDPEPIL
* Function tsocmdf literal pool
         DS    0F
         LTORG
* Function tsocmdf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
