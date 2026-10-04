         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __nwtx9s prologue
@@NWTX9S PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __nwtx9s code
         LA    5,4(,11)
         LA    2,8(,11)
         ST    2,96(13)
         SLR   7,7
         LR    3,7
         L     4,4(11)
         CR    7,4
         BNL   @@L3
@@L6     EQU   *
         L     8,96(13)
         A     8,=F'4'
         ST    8,96(13)
         L     2,=F'-4'
         L     6,0(2,8)
         LTR   6,6
         BE    @@L3
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         AR    7,15
         A     3,=F'1'
         CR    3,4
         BL    @@L6
@@L3     EQU   *
         L     12,0(,10)
         L     2,4(11)
         SLL   2,1
         AR    2,7
         MVC   88(4,13),=F'1'
         A     2,=F'8'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    9,15
         LTR   15,15
         BE    @@L7
         L     2,0(11)
         STH   2,0(15)
         MVC   2(2,15),2(5)
         A     5,=F'4'
         ST    5,96(13)
         LR    8,15
         A     8,=F'4'
@@L14    EQU   *
         L     2,4(11)
         LR    3,2
         BCTR  2,0
         ST    2,4(11)
         LTR   3,3
         BNH   @@L7
         L     3,96(13)
         A     3,=F'4'
         ST    3,96(13)
         L     2,=F'-4'
         L     6,0(2,3)
         LTR   6,6
         BE    @@L7
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         STH   15,0(8)
         LR    4,8
         A     4,=F'2'
         LR    5,15
         LR    2,6
         LR    3,15
         MVCL  4,2
         AR    8,15
         A     8,=F'2'
         B     @@L14
@@L7     EQU   *
         L     12,0(,10)
         LR    15,9
* Function __nwtx9s epilogue
         PDPEPIL
* Function __nwtx9s literal pool
         DS    0F
         LTORG
* Function __nwtx9s page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
