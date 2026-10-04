         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func puts prologue
PUTS     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function puts code
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         L     3,0(15)
         SLR   4,4
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         LA    4,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(11)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPUTS)
         BALR  14,15
         LR    2,15
         L     5,=F'-1'
         CLR   15,5
         BE    @@L3
         MVC   88(4,13),=F'21'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPUTC)
         BALR  14,15
         LR    2,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L4
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function puts epilogue
         PDPEPIL
* Function puts literal pool
         DS    0F
         LTORG
* Function puts page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
