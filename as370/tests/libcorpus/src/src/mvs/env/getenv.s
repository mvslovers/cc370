         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func getenv prologue
GETENV   PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function getenv code
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L1
         LR    2,15
         A     2,=F'32'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   88(4,13),0(11)
         LA    3,104(,13)
         ST    3,92(13)
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@FINDEN)
         BALR  14,15
         LR    3,15
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
         LR    15,3
* Function getenv epilogue
         PDPEPIL
* Function getenv literal pool
         DS    0F
         LTORG
* Function getenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
