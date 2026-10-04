         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'DSAB'
         DC    X'0'
@@LC1    EQU   *
         DC    C'        '
         DC    X'0'
         DS    0F
* X-func *@@NXDSAB prologue
@@NXDSAB PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@NXDSAB code
         L     15,0(11)
         L     2,8(11)
         LTR   15,15
         BNE   @@L2
         MVC   88(4,13),4(11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@GTDSAB)
         BALR  14,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         L     4,=A(@@LC0)
         CLC   0(4,15),0(4)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L8
         L     15,4(15)
         LTR   2,2
         BE    @@L3
         CLI   0(2),64
         BE    @@L3
         LTR   15,15
         BE    @@L8
         CLC   0(4,15),0(4)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L9
         LR    15,3
         B     @@L3
@@L9     EQU   *
         L     12,0(,10)
         L     2,16(15)
         L     3,=A(@@LC1)
         CLC   4(8,2),0(3)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
@@L8     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L3     EQU   *
         L     12,0(,10)
* Function *@@NXDSAB epilogue
         PDPEPIL
* Function *@@NXDSAB literal pool
         DS    0F
         LTORG
* Function *@@NXDSAB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
