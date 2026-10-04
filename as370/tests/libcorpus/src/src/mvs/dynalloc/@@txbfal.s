         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'FULL'
         DC    X'0'
@@LC1    EQU   *
         DC    C'DOUBLE'
         DC    X'0'
         DS    0F
* X-func __txbfal prologue
@@TXBFAL PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txbfal code
         L     3,4(11)
         LA    8,1(0,0)
         LTR   3,3
         BE    @@L9
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L9
         LR    6,3
         LR    7,15
         L     4,=A(@@LC0)
         LR    5,15
         LA    2,1(0,0)
         CLCL  6,4
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         STC   8,104(13)
         B     @@L6
@@L5     EQU   *
         L     12,0(,10)
         LR    6,3
         LR    7,15
         L     4,=A(@@LC1)
         LR    5,15
         LA    2,1(0,0)
         CLCL  6,4
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L9
         MVI   104(13),2
@@L6     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'46'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         LA    2,104(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L9
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    8,15
@@L9     EQU   *
         L     12,0(,10)
         LR    15,8
* Function __txbfal epilogue
         PDPEPIL
* Function __txbfal literal pool
         DS    0F
         LTORG
* Function __txbfal page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
