         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func strdup prologue
STRDUP   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strdup code
         L     7,0(11)
         SLR   15,15
         LTR   7,7
         BE    @@L2
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
         MVC   88(4,13),=F'1'
         A     6,=F'1'
         ST    6,92(13)
         BCTR  6,0
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         LR    4,15
         LR    5,6
         LR    2,7
         LR    3,6
         MVCL  4,2
@@L2     EQU   *
         L     12,0(,10)
* Function strdup epilogue
         PDPEPIL
* Function strdup literal pool
         DS    0F
         LTORG
* Function strdup page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
