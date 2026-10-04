         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txdcbd prologue
@@TXDCBD PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txdcbd code
         L     2,4(11)
         LA    3,1(0,0)
         LTR   2,2
         BE    @@L5
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         LA    4,44(0,0)
         CR    15,4
         BH    @@L5
         ST    4,88(13)
         ST    3,92(13)
         ST    15,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L5
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L5
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __txdcbd epilogue
         PDPEPIL
* Function __txdcbd literal pool
         DS    0F
         LTORG
* Function __txdcbd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
