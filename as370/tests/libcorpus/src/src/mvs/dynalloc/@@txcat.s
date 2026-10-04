         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    X'2'
         DC    X'0'
         DS    0F
* X-func __txcat prologue
@@TXCAT  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txcat code
         LA    2,1(0,0)
         MVC   88(4,13),=F'5'
         ST    2,92(13)
         ST    2,96(13)
         MVC   100(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    2,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __txcat epilogue
         PDPEPIL
* Function __txcat literal pool
         DS    0F
         LTORG
* Function __txcat page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
