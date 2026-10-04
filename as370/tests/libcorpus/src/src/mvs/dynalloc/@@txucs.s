         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'FOLD'
         DC    X'0'
@@LC1    EQU   *
         DC    C'VERIFY'
         DC    X'0'
         DS    0F
* X-func __txucs prologue
@@TXUCS  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txucs code
         L     3,4(11)
         LA    5,1(0,0)
         LR    4,3
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    4,15
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
         LTR   4,4
         BE    @@L10
         L     2,=A(@@LC0)
         CLC   0(5,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         MVC   88(4,13),=F'42'
         B     @@L12
@@L5     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC1)
         CLC   0(7,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L7
         MVC   88(4,13),=F'43'
@@L12    EQU   *
         L     12,0(,10)
         ST    15,92(13)
         ST    15,96(13)
         ST    15,100(13)
         B     @@L11
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'41'
         MVC   92(4,13),=F'1'
         ST    4,96(13)
         ST    3,100(13)
@@L11    EQU   *
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
         LR    5,15
@@L10    EQU   *
         L     12,0(,10)
         LR    15,5
* Function __txucs epilogue
         PDPEPIL
* Function __txucs literal pool
         DS    0F
         LTORG
* Function __txucs page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
