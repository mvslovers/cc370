         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C' ,'
         DC    X'0'
@@LC1    EQU   *
         DC    C','
         DC    X'0'
@@LC2    EQU   *
         DC    X'0'
         DS    0F
* X-func __txspac prologue
@@TXSPAC PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txspac code
         L     9,0(11)
         L     6,4(11)
         LA    7,1(0,0)
         LR    15,6
         LTR   6,6
         BE    @@L3
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         ST    15,104(13)
         MVC   88(4,13),=F'1'
         A     15,=F'1'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    8,15
         L     15,104(13)
         LTR   15,15
         BE    @@L5
         LTR   8,8
         BE    @@L5
         LR    4,8
         LR    5,15
         LR    2,6
         LR    3,15
         MVCL  4,2
         ST    8,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    3,15
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    5,15
         LR    15,3
         LTR   3,3
         BE    @@L8
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         ST    15,104(13)
         LA    3,104(,13)
         MVC   88(4,13),=F'10'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'3'
         LA    2,105(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         ST    9,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BNE   @@L5
         LA    7,1(0,0)
         LR    15,4
         LTR   4,4
         BE    @@L12
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         ST    15,104(13)
         MVC   88(4,13),=F'11'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'3'
         A     3,=F'1'
         ST    3,100(13)
         BCTR  3,0
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         ST    9,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    7,15
         LR    15,5
         LTR   5,5
         BE    @@L15
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
@@L15    EQU   *
         L     12,0(,10)
         ST    15,104(13)
         LTR   15,15
         BE    @@L5
         LA    7,1(0,0)
         MVC   88(4,13),=F'12'
         ST    7,92(13)
         MVC   96(4,13),=F'3'
         AR    3,7
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         ST    9,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    7,15
@@L5     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L18
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L18    EQU   *
         L     12,0(,10)
         LR    15,7
* Function __txspac epilogue
         PDPEPIL
* Function __txspac literal pool
         DS    0F
         LTORG
* Function __txspac page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
