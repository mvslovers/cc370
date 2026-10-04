         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBSOCK'
         DC    X'0'
         DS    0F
* X-func __soadd prologue
@@SOADD  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __soadd code
         L     5,4(11)
         L     6,8(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    4,15
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'48'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         MVC   0(9,15),0(2)
         MVC   8(4,15),0(11)
         LTR   5,5
         BE    @@L4
         MVC   16(16,15),0(5)
@@L4     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L5
         MVC   32(16,3),0(6)
@@L5     EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'28'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         L     15,=F'-1'
* Function __soadd epilogue
         PDPEPIL
* Function __soadd literal pool
         DS    0F
         LTORG
* Function __soadd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
