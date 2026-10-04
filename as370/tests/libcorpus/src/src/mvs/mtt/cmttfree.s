         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *CMTTFREE prologue
CMTTFREE PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *CMTTFREE code
         L     4,0(11)
         LTR   4,4
         BE    @@L1
         L     3,0(4)
         LTR   3,3
         BE    @@L4
         L     2,12(3)
         LTR   2,2
         BE    @@L5
         A     3,=F'12'
         ST    3,88(13)
         A     3,=F'-12'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         L     2,8(3)
         LTR   2,2
         BE    @@L6
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         MVC   0(4,4),=F'0'
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function *CMTTFREE epilogue
         PDPEPIL
* Function *CMTTFREE literal pool
         DS    0F
         LTORG
* Function *CMTTFREE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
