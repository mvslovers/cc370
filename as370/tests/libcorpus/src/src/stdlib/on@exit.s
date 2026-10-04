         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func on_exit prologue
ON@EXIT  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function on_exit code
         L     5,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    2,15
         L     4,=F'-1'
         LTR   5,5
         BE    @@L2
         LTR   15,15
         BE    @@L2
         LR    3,15
         A     3,=F'16'
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L3
         A     2,=F'20'
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LR    15,4
* Function on_exit epilogue
         PDPEPIL
* Function on_exit literal pool
         DS    0F
         LTORG
* Function on_exit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
