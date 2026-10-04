         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __nwtx9a prologue
@@NWTX9A PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __nwtx9a code
         SLR   8,8
         LR    7,8
@@L17    EQU   *
         C     8,4(11)
         BNL   @@L15
         LR    2,8
         SLL   2,2
         L     3,8(11)
         L     2,0(2,3)
         LTR   2,2
         BE    @@L4
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         AR    7,15
@@L4     EQU   *
         L     12,0(,10)
         A     8,=F'1'
         B     @@L17
@@L15    EQU   *
         L     12,0(,10)
         L     2,4(11)
         AR    2,2
         AR    2,7
         MVC   88(4,13),=F'1'
         A     2,=F'8'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,104(13)
         LTR   15,15
         BE    @@L7
         L     4,0(11)
         STH   4,0(15)
         L     9,4(11)
         STH   9,2(15)
         LR    6,15
         A     6,=F'4'
         SLR   8,8
         CR    8,9
         BNL   @@L7
@@L13    EQU   *
         LR    15,8
         SLL   15,2
         ST    15,96(13)
         L     3,8(11)
         L     2,0(15,3)
         LR    7,2
         LTR   2,2
         BE    @@L12
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    7,15
         STH   15,0(6)
         LR    4,6
         A     4,=F'2'
         LR    5,15
         L     9,8(11)
         L     15,96(13)
         L     2,0(15,9)
         LR    3,7
         MVCL  4,2
@@L12    EQU   *
         L     12,0(,10)
         AR    6,7
         A     6,=F'2'
         A     8,=F'1'
         C     8,4(11)
         BL    @@L13
@@L7     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function __nwtx9a epilogue
         PDPEPIL
* Function __nwtx9a literal pool
         DS    0F
         LTORG
* Function __nwtx9a page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
