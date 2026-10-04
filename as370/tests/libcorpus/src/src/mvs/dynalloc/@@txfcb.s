         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'ALIGN'
         DC    X'0'
@@LC1    EQU   *
         DC    X'8'
         DC    X'0'
@@LC2    EQU   *
         DC    C'VERIFY'
         DC    X'0'
@@LC3    EQU   *
         DC    X'4'
         DC    X'0'
         DS    0F
* X-func __txfcb prologue
@@TXFCB  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txfcb code
         L     4,4(11)
         LA    3,1(0,0)
         LTR   4,4
         BE    @@L10
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BNH   @@L10
         L     2,=A(@@LC0)
         CLC   0(6,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         MVC   88(4,13),=F'38'
         ST    3,92(13)
         ST    3,96(13)
         MVC   100(4,13),=A(@@LC1)
         B     @@L12
@@L5     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC2)
         CLC   0(7,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L7
         MVC   88(4,13),=F'38'
         ST    3,92(13)
         ST    3,96(13)
         MVC   100(4,13),=A(@@LC3)
         B     @@L12
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'37'
         ST    3,92(13)
         ST    15,96(13)
         ST    4,100(13)
@@L12    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    3,15
@@L10    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __txfcb epilogue
         PDPEPIL
* Function __txfcb literal pool
         DS    0F
         LTORG
* Function __txfcb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
