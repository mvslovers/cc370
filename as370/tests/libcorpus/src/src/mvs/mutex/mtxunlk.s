         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'MUTEX.%08X'
         DC    X'0'
         DS    0F
* X-func mtxunlk prologue
MTXUNLK  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function mtxunlk code
         L     4,0(11)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(MTXHELD)
         BALR  14,15
         LTR   15,15
         BE    @@L1
         L     2,4(4)
         BCTR  2,0
         ST    2,4(4)
         LTR   2,2
         BNE   @@L1
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         LR    3,15
         A     3,=F'340'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    2,15
@@L10    EQU   *
         LTR   2,2
         BE    @@L4
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         CLR   15,4
         BNE   @@L7
         ST    3,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L4
@@L7     EQU   *
         L     12,0(,10)
         BCTR  2,0
         B     @@L10
@@L4     EQU   *
         L     12,0(,10)
         MVC   0(4,4),=F'0'
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=F'0'
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(@@LKRNUF)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function mtxunlk epilogue
         PDPEPIL
* Function mtxunlk literal pool
         DS    0F
         LTORG
* Function mtxunlk page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
