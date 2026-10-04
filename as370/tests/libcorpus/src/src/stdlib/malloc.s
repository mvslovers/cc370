         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'Out of memory, bytes needed=%u'
         DC    X'0'
         DS    0F
* X-func malloc prologue
MALLOC   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function malloc code
         L     3,0(11)
         SLR   2,2
         L     4,=F'6291456'
         CLR   3,4
         BH    @@L5
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@GETM)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L4
@@L5     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'12'
         MVC   88(4,13),=A(@@LC0)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@WTOTB)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function malloc epilogue
         PDPEPIL
* Function malloc literal pool
         DS    0F
         LTORG
* Function malloc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
