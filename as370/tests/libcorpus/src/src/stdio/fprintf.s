         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func fprintf prologue
FPRINTF  PDPPRLG CINDEX=0,FRAME=8296,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fprintf code
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'8192'
         MVC   96(4,13),4(11)
         LA    2,8(,11)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         L     2,=F'8192'
         CLR   15,2
         BNH   @@L2
         LR    15,2
@@L2     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'1'
         ST    15,96(13)
         MVC   100(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(FWRITE)
         BALR  14,15
* Function fprintf epilogue
         PDPEPIL
* Function fprintf literal pool
         DS    0F
         LTORG
* Function fprintf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
