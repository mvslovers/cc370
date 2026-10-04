         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txexpd prologue
@@TXEXPD PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txexpd code
         L     2,4(11)
         LA    3,1(0,0)
         LTR   2,2
         BE    @@L6
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    4,5(0,0)
         CLR   15,4
         BNE   @@L6
         MVC   88(4,13),=F'34'
         ST    3,92(13)
         ST    15,96(13)
         ST    2,100(13)
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
         LR    3,15
@@L6     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __txexpd epilogue
         PDPEPIL
* Function __txexpd literal pool
         DS    0F
         LTORG
* Function __txexpd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
