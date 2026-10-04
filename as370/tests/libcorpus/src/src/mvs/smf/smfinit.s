         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'smf_init'
* Program text area
         DS    0F
* X-func *SMFINIT prologue
SMFINIT  PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *SMFINIT code
         SLR   6,6
         SLR   7,7
         LR    8,6
         LR    9,7
         ST    6,104(13)
         ST    7,4+104(13)
         ST    6,112(13)
         ST    7,4+112(13)
         ST    6,120(13)
         ST    7,4+120(13)
         ST    6,128(13)
         ST    7,4+128(13)
         ST    6,136(13)
         ST    7,4+136(13)
         L     5,0(11)
         L     2,4(11)
         STH   2,0(5)
         MVC   2(2,5),=H'0'
         MVI   4(5),2
         MVC   5(1,5),11(11)
         MVC   88(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(TIME)
         BALR  14,15
         ST    15,96(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(LOCALTIM)
         BALR  14,15
         L     2,=F'360000'
         SRDA  2,32
         L     4,8(15)
         MR    2,4
         L     4,4(15)
         MH    4,=H'6000'
         AR    4,3
         L     2,0(15)
         MH    2,=H'100'
         AR    4,2
         LR    2,4
         SRL   2,24
         STC   2,6(5)
         LR    2,4
         SRL   2,16
         STC   2,7(5)
         LR    2,4
         SRL   2,8
         STC   2,8(5)
         STC   4,9(5)
         L     2,20(15)
         LR    6,2
         SRDA  6,32
         LA    3,100(0,0)
         DR    6,3
         L     15,28(15)
         A     15,=F'1'
         SLR   4,4
         LA    7,99(0,0)
         CR    2,7
         BNH   @@L2
         LA    4,1(0,0)
@@L2     EQU   *
         L     12,0(,10)
         STC   4,10(5)
         LR    8,6
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         LR    2,9
         SLL   2,4
         ST    6,104(13)
         L     6,104(13)
         L     7,4+104(13)
         SRDA  6,32
         ST    6,104(13)
         ST    7,4+104(13)
         LA    3,10(0,0)
         DR    6,3
         OR    2,6
         STC   2,11(5)
         ST    15,112(13)
         L     6,112(13)
         L     7,4+112(13)
         SRDA  6,32
         LA    2,100(0,0)
         DR    6,2
         ST    6,112(13)
         ST    7,4+112(13)
         L     2,116(13)
         SLL   2,4
         ST    15,120(13)
         L     6,120(13)
         L     7,4+120(13)
         SRDA  6,32
         LA    3,10(0,0)
         DR    6,3
         ST    6,120(13)
         ST    7,4+120(13)
         ST    7,128(13)
         L     6,128(13)
         L     7,4+128(13)
         SRDA  6,32
         ST    6,128(13)
         ST    7,4+128(13)
         DR    6,3
         OR    2,6
         STC   2,12(5)
         ST    15,136(13)
         L     6,136(13)
         L     7,4+136(13)
         SRDA  6,32
         DR    6,3
         ST    6,136(13)
         ST    7,4+136(13)
         L     2,136(13)
         SLL   2,4
         O     2,=XL4'0C'
         STC   2,13(5)
         LA    1,88(,13)
         L     15,=V(@@SMFID)
         BALR  14,15
         LTR   15,15
         BE    @@L1
         MVC   14(4,5),0(15)
@@L1     EQU   *
         L     12,0(,10)
* Function *SMFINIT epilogue
         PDPEPIL
* Function *SMFINIT literal pool
         DS    0F
         LTORG
* Function *SMFINIT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
