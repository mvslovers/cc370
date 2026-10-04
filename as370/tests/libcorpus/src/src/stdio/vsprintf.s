         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func vsprintf prologue
VSPRINTF PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vsprintf code
         L     3,0(11)
         MVC   88(4,13),4(11)
         MVC   92(4,13),8(11)
         MVC   96(4,13),=F'0'
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(VVPRINTF)
         BALR  14,15
         LTR   15,15
         BL    @@L2
         SLR   4,4
         STC   4,0(15,3)
@@L2     EQU   *
         L     12,0(,10)
* Function vsprintf epilogue
         PDPEPIL
* Function vsprintf literal pool
         DS    0F
         LTORG
* Function vsprintf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
