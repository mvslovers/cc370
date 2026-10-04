         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func vwtorf prologue
VWTORF   PDPPRLG CINDEX=0,FRAME=4200,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vwtorf code
         LA    4,104(,13)
         ST    4,88(13)
         MVC   92(4,13),=F'4096'
         MVC   96(4,13),8(11)
         MVC   100(4,13),12(11)
         LA    1,88(,13)
         L     15,=V(VSNPRINT)
         BALR  14,15
         LR    3,15
         LA    2,4095(0,0)
         CLR   15,2
         BNH   @@L2
         LR    3,2
@@L2     EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,104(13,3)
         ST    4,88(13)
         MVC   92(4,13),=F'21'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L3
@@L6     EQU   *
         MVI   0(2),0
         A     2,=F'1'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),=F'21'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L6
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L1
@@L3     EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,104(13,3)
         MVC   88(4,13),0(11)
         MVC   92(4,13),4(11)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(WTOR)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function vwtorf epilogue
         PDPEPIL
* Function vwtorf literal pool
         DS    0F
         LTORG
* Function vwtorf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
