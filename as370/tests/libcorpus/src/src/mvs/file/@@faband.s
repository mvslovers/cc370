         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'F I L E'
         DC    X'0'
         DS    0F
* X-func __fabandon prologue
@@FABAND PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fabandon code
         L     3,0(11)
         SLR   4,4
         LR    5,4
         L     15,=F'-1'
         LTR   3,3
         BE    @@L1
         L     2,=A(@@LC0)
         CLC   0(8,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L1
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         L     2,28(3)
         LTR   2,2
         BE    @@L4
         ST    2,32(3)
@@L4     EQU   *
         L     12,0(,10)
         ST    4,24(3)
         LH    2,40(3)
         N     2,=F'16384'
         LTR   2,2
         BE    @@L5
         MVC   88(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(@@ADISC)
         BALR  14,15
         MVC   88(4,13),=V(@@ACLOSE)
         MVC   92(4,13),8(3)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNL   @@L6
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         L     15,=F'-3'
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         NC    40(2,3),=H'-16385'
         ST    4,8(3)
         ST    4,12(3)
@@L5     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@FPTERM)
         BALR  14,15
         LR    4,15
         LR    15,5
         LTR   5,5
         BNE   @@L1
         L     15,=F'-2'
         LTR   4,4
         BNE   @@L1
         LR    15,4
@@L1     EQU   *
         L     12,0(,10)
* Function __fabandon epilogue
         PDPEPIL
* Function __fabandon literal pool
         DS    0F
         LTORG
* Function __fabandon page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
