         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txlrec prologue
@@TXLREC PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txlrec code
         L     2,4(11)
         LA    5,1(0,0)
         LR    3,2
         LTR   2,2
         BE    @@L3
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         LR    3,15
@@L3     EQU   *
         L     12,0(,10)
         ST    3,104(13)
         LTR   2,2
         BE    @@L12
         LA    4,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'231'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         MVC   104(4,13),=F'32768'
         B     @@L6
@@L5     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),=F'210'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,3
         LTR   15,15
         BE    @@L7
         SLL   2,10
         ST    2,104(13)
         L     3,=F'32760'
         CR    2,3
         BNH   @@L6
         ST    3,104(13)
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         L     2,=F'32760'
         CR    3,2
         BNH   @@L6
         ST    2,104(13)
@@L6     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'66'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'2'
         A     4,=F'2'
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L12
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    5,15
@@L12    EQU   *
         L     12,0(,10)
         LR    15,5
* Function __txlrec epilogue
         PDPEPIL
* Function __txlrec literal pool
         DS    0F
         LTORG
* Function __txlrec page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
