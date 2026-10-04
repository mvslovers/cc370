         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@FREEVL prologue
@@FREEVL PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@FREEVL code
         L     4,0(11)
         LTR   4,4
         BE    @@L1
         L     2,0(4)
         ST    2,96(13)
         LTR   2,2
         BE    @@L1
         LA    5,96(,13)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    3,15
@@L13    EQU   *
         LTR   3,3
         BE    @@L12
         ST    5,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L7
         L     15,36(15)
         LTR   15,15
         BE    @@L9
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   36(4,2),=F'0'
@@L9     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         BCTR  3,0
         B     @@L13
@@L12    EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         MVC   0(4,4),=F'0'
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function *@@FREEVL epilogue
         PDPEPIL
* Function *@@FREEVL literal pool
         DS    0F
         LTORG
* Function *@@FREEVL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
