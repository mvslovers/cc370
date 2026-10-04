         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fwrite prologue
FWRITE   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fwrite code
         L     4,12(11)
         SLR   3,3
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         LA    3,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(@@FWRITE)
         BALR  14,15
         LR    2,15
         LTR   3,3
         BE    @@L3
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function fwrite epilogue
         PDPEPIL
* Function fwrite literal pool
         DS    0F
         LTORG
* Function fwrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
