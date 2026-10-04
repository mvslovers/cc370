         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'F I L E'
         DC    X'0'
         DS    0F
* X-func fclose prologue
FCLOSE   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function fclose code
         L     3,0(11)
         SLR   5,5
         LTR   3,3
         BE    @@L3
         L     2,=A(@@LC0)
         CLC   0(8,3),0(2)
         LA    4,1(0,0)
         BH    *+12
         BL    *+6
         SLR   4,4
         LNR   4,4
         LTR   4,4
         BNE   @@L3
         LR    6,5
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L5
         LA    6,1(0,0)
@@L5     EQU   *
         L     12,0(,10)
         LH    2,40(3)
         N     2,=F'16384'
         LTR   2,2
         BE    @@L6
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@FFLUSH)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         L     5,=F'-1'
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(@@ACLOSE)
         BALR  14,15
         LR    2,15
         ST    4,8(3)
         ST    4,12(3)
         LTR   15,15
         BE    @@L6
         L     5,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LA    4,28(0,0)
         LA    7,12(0,0)
         CLR   2,7
         BE    @@L10
         LA    4,5(0,0)
@@L10    EQU   *
         L     12,0(,10)
         ST    4,0(15)
@@L6     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@FPTERM)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function fclose epilogue
         PDPEPIL
* Function fclose literal pool
         DS    0F
         LTORG
* Function fclose page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
