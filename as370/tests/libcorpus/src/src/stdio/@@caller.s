         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    X'0'
         DS    0F
* X-func __caller prologue
@@CALLER PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __caller code
         L     15,0(11)
         LTR   15,15
         BNE   @@L2
         L     15,=A(@@LC0)
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         MVI   0(15),0
         LA    2,88(,13)
         DS    0H
        L      1,4(,13)        => callers stack
        L      1,4(,1)         => callers stack
        L      1,4(,1)         => callers stack
        L      1,16(,1)        => function ep address
        ST     1,0(,2)        return ep address
         L     3,88(13)
         CLI   0(3),71
         BNE   @@L3
         CLI   1(3),240
         BNE   @@L3
         A     3,=F'4'
         SLR   2,2
         IC    2,0(3)
         LR    6,15
         LR    7,2
         LR    4,3
         A     4,=F'1'
         LR    5,2
         MVCL  6,4
         SLR   2,2
         IC    2,0(3)
         SLR   3,3
         STC   3,0(2,15)
@@L3     EQU   *
         L     12,0(,10)
* Function __caller epilogue
         PDPEPIL
* Function __caller literal pool
         DS    0F
         LTORG
* Function __caller page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
