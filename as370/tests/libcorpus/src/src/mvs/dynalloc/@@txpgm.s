         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txpgm prologue
@@TXPGM  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txpgm code
         L     3,4(11)
         LA    4,1(0,0)
         LR    15,3
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    2,15
         BCTR  2,0
         LA    5,7(0,0)
         CLR   2,5
         BH    @@L6
         MVC   88(4,13),=F'25'
         MVC   92(4,13),=F'1'
         ST    15,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L6
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    4,15
@@L6     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __txpgm epilogue
         PDPEPIL
* Function __txpgm literal pool
         DS    0F
         LTORG
* Function __txpgm page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
