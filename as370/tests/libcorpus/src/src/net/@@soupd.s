         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __soupd prologue
@@SOUPD  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __soupd code
         L     6,0(11)
         L     3,4(11)
         L     5,8(11)
         SLR   4,4
         ST    4,104(13)
         ST    6,88(13)
         LA    2,104(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@SOFIND)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         ST    6,88(13)
         ST    3,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@SOADD)
         BALR  14,15
         LR    4,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L4
         L     2,104(13)
         MVC   16(16,2),0(3)
@@L4     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L3
         L     2,104(13)
         MVC   32(16,2),0(5)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __soupd epilogue
         PDPEPIL
* Function __soupd literal pool
         DS    0F
         LTORG
* Function __soupd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
