         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'reread'
         DC    X'0'
@@LC1    EQU   *
         DC    C'free'
         DC    X'0'
@@LC2    EQU   *
         DC    C'leave'
         DC    X'0'
@@LC3    EQU   *
         DC    C'rewind'
         DC    X'0'
         DS    0F
* X-func osbclose prologue
OSBCLOSE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osbclose code
         L     3,0(11)
         L     15,4(11)
         L     4,12(11)
         LTR   3,3
         BE    @@L1
         LR    2,3
         O     2,=F'-2147483648'
         ST    2,96(13)
         LTR   15,15
         BE    @@L4
         L     2,=A(@@LC0)
         CLC   0(7,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         LR    2,3
         O     2,=F'-1879048192'
         B     @@L15
@@L5     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC1)
         CLC   0(5,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L7
         LR    2,3
         O     2,=F'-1610612736'
         B     @@L15
@@L7     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC2)
         CLC   0(6,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L9
         LR    2,3
         O     2,=F'-1342177280'
         B     @@L15
@@L9     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC3)
         CLC   0(7,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L4
         LR    2,3
         O     2,=F'-1073741824'
@@L15    EQU   *
         L     12,0(,10)
         ST    2,96(13)
@@L4     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         LTR   4,4
         BE    @@L12
         LR    1,2
         SVC   23         TCLOSE
         B     @@L1
@@L12    EQU   *
         LR    1,2
         SVC   20         CLOSE
         L     12,0(,10)
         L     2,100(3)
         LTR   2,2
         BE    @@L13
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         ST    4,100(3)
@@L13    EQU   *
         L     12,0(,10)
         L     2,8(11)
         LTR   2,2
         BE    @@L1
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function osbclose epilogue
         PDPEPIL
* Function osbclose literal pool
         DS    0F
         LTORG
* Function osbclose page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
