         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txdest prologue
@@TXDEST PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txdest code
         L     8,0(11)
         L     6,4(11)
         LA    7,1(0,0)
         LTR   6,6
         BE    @@L3
         ST    6,88(13)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,39(0,0)
         CLR   15,2
         BH    @@L3
         LA    4,104(,13)
         LR    5,15
         LR    2,6
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,104(13,15)
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L3
         MVI   0(15),0
         AR    2,7
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         MVC   88(4,13),=F'99'
         ST    7,92(13)
         ST    15,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         ST    8,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         MVC   88(4,13),=F'88'
         ST    7,92(13)
         ST    15,96(13)
         ST    3,100(13)
         B     @@L15
@@L4     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         MVC   88(4,13),=F'88'
         ST    7,92(13)
         ST    15,96(13)
         ST    6,100(13)
@@L15    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         ST    8,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         SLR   7,7
@@L3     EQU   *
         L     12,0(,10)
         LR    15,7
* Function __txdest epilogue
         PDPEPIL
* Function __txdest literal pool
         DS    0F
         LTORG
* Function __txdest page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
