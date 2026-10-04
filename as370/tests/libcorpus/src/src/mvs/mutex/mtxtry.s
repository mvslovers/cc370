         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'MUTEX.%08X'
         DC    X'0'
         DS    0F
* X-func mtxtry prologue
MTXTRY   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxtry code
         L     3,0(11)
         SLR   2,2
         L     4,540(2)
         MVC   88(4,13),=A(@@LC0)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNTF)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         LA    2,8(0,0)
         CLR   15,2
         BNE   @@L2
@@L3     EQU   *
         L     12,0(,10)
         ST    4,0(3)
         L     2,4(3)
         A     2,=F'1'
         ST    2,4(3)
         LTR   15,15
         BNE   @@L4
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         A     15,=F'340'
         ST    15,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L2     EQU   *
         L     12,0(,10)
* Function mtxtry epilogue
         PDPEPIL
* Function mtxtry literal pool
         DS    0F
         LTORG
* Function mtxtry page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
