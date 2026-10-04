         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txsyso prologue
@@TXSYSO PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txsyso code
         L     15,4(11)
         LA    2,1(0,0)
         LTR   15,15
         BE    @@L2
         MVC   88(4,13),=F'24'
         ST    2,92(13)
         ST    2,96(13)
         B     @@L7
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'24'
         ST    15,92(13)
         ST    15,96(13)
@@L7     EQU   *
         L     12,0(,10)
         ST    15,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L5
         LR    2,15
@@L5     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __txsyso epilogue
         PDPEPIL
* Function __txsyso literal pool
         DS    0F
         LTORG
* Function __txsyso page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
