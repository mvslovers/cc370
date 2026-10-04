         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osxwrite prologue
OSXWRITE PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osxwrite code
         L     7,0(11)
         L     8,16(11)
         LA    4,104(,13)
         LA    5,24(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         LA    6,128(,13)
         LR    4,6
         LA    5,40(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         MVC   168(4,13),=F'0'
         LA    2,163(,13)
         O     2,=F'822083584'
         ST    2,104(13)
         MVC   108(4,13),=F'1073741829'
         LA    3,104(,13)
         LR    2,3
         O     2,=F'134217728'
         ST    2,112(13)
         MVC   116(4,13),=F'1073741824'
         L     2,12(11)
         O     2,=F'83886080'
         ST    2,120(13)
         LH    2,62(7)
         N     2,=XL4'0000FFFF'
         ST    2,124(13)
         ST    7,88(13)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         LA    2,160(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(OSXCALC)
         BALR  14,15
         LTR   15,15
         BNL   @@L2
         MVI   131(13),8
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         MVI   128(13),67
         LA    2,168(,13)
         ST    2,132(13)
         ST    3,144(13)
         ST    7,148(13)
         EXCP (6)
         WAIT 1,ECB=(2)
         SLR   15,15
         IC    15,168(13)
         LA    2,127(0,0)
         CLR   15,2
         BNE   @@L3
         SLR   15,15
@@L3     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L5
         MVC   0(1,8),130(13)
         MVC   1(1,8),131(13)
@@L5     EQU   *
         L     12,0(,10)
* Function osxwrite epilogue
         PDPEPIL
* Function osxwrite literal pool
         DS    0F
         LTORG
* Function osxwrite page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
