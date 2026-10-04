         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'DSAB'
         DC    X'0'
         DS    0F
* X-func *@@GTDSAB prologue
@@GTDSAB PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@GTDSAB code
         L     2,0(11)
         L     6,4(11)
         LR    3,2
         LTR   2,2
         BNE   @@L3
         L     3,540(2)
         B     @@L3
@@L27    EQU   *
         SLR   15,15
         B     @@L5
@@L3     EQU   *
         L     12,0(,10)
         L     2,180(3)
         L     2,320(2)
         L     15,12(2)
         LTR   6,6
         BE    @@L5
         SLR   4,4
         IC    3,0(6)
         CLM   3,1,=XL1'40'
         BNE   @@L7
         LA    4,1(0,0)
@@L7     EQU   *
         L     12,0(,10)
         LR    2,3
         N     2,=XL4'000000FF'
         BCTR  2,0
         SRL   2,31
         OR    2,4
         LTR   2,2
         BNE   @@L5
         LR    5,2
         CLM   3,1,=XL1'00'
         BE    @@L16
         LR    4,6
@@L12    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,88(5,13)
         A     5,=F'1'
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L10
         LA    2,7(0,0)
         CLR   5,2
         BNH   @@L12
@@L10    EQU   *
         L     12,0(,10)
         LA    2,7(0,0)
         CLR   5,2
         BH    @@L25
@@L16    EQU   *
         L     12,0(,10)
         LA    2,64(0,0)
         STC   2,88(5,13)
         A     5,=F'1'
         B     @@L10
@@L25    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L5
@@L22    EQU   *
         L     3,16(15)
         L     2,=A(@@LC0)
         CLC   0(4,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L27
         CLC   4(8,3),88(13)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L5
         L     15,4(15)
         LTR   15,15
         BNE   @@L22
@@L5     EQU   *
         L     12,0(,10)
* Function *@@GTDSAB epilogue
         PDPEPIL
* Function *@@GTDSAB literal pool
         DS    0F
         LTORG
* Function *@@GTDSAB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
