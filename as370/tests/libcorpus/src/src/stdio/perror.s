         COPY  PDPTOP
         CSECT
         DS    0F
@V1      EQU   *
         DS    XL24
* Program text area
@@LC0    EQU   *
         DC    C'%s: '
         DC    X'0'
@@LC1    EQU   *
         DC    C'unknown error:%d'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s'
         DC    X'15'
         DC    X'0'
         DS    0F
* X-func perror prologue
PERROR   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function perror code
         L     4,0(11)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   88(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(STRERROR)
         BALR  14,15
         LR    3,15
         LTR   4,4
         BE    @@L2
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L2
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         MVC   88(4,13),0(15)
         MVC   92(4,13),=A(@@LC0)
         ST    4,96(13)
         LA    1,88(,13)
         L     15,=V(FPRINTF)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L3
         L     3,=A(@V1)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         MVC   88(4,13),0(15)
         MVC   92(4,13),=A(@@LC2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(FPRINTF)
         BALR  14,15
* Function perror epilogue
         PDPEPIL
* Function perror literal pool
         DS    0F
         LTORG
* Function perror page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
