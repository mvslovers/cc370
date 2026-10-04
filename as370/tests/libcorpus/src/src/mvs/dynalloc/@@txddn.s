         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txddn prologue
@@TXDDN  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txddn code
         L     2,4(11)
         LA    3,1(0,0)
         LTR   2,2
         BE    @@L4
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         ST    3,88(13)
         ST    3,92(13)
         ST    15,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    3,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __txddn epilogue
         PDPEPIL
* Function __txddn literal pool
         DS    0F
         LTORG
* Function __txddn page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
