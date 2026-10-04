         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C' ,'
         DC    X'0'
         DS    0F
* X-func __txvols prologue
@@TXVOLS PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txvols code
         L     8,4(11)
         LA    9,1(0,0)
         LR    6,8
         LTR   8,8
         BE    @@L3
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
@@L3     EQU   *
         L     12,0(,10)
         MVC   104(4,13),=F'0'
         MVC   88(4,13),=F'1'
         A     6,=F'1'
         ST    6,92(13)
         BCTR  6,0
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   6,6
         BE    @@L5
         LTR   15,15
         BE    @@L5
         LR    4,15
         LR    5,6
         LR    2,8
         LR    3,6
         MVCL  4,2
         ST    15,88(13)
@@L17    EQU   *
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         BE    @@L16
         LA    2,104(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         MVC   88(4,13),=F'0'
         B     @@L17
@@L16    EQU   *
         L     12,0(,10)
         L     2,104(13)
         LTR   2,2
         BE    @@L5
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         MVC   88(4,13),=F'16'
         ST    15,92(13)
         MVC   96(4,13),104(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX9A)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    9,15
@@L5     EQU   *
         L     12,0(,10)
         L     2,104(13)
         LTR   2,2
         BE    @@L13
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L13    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L14
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         LR    15,9
* Function __txvols epilogue
         PDPEPIL
* Function __txvols literal pool
         DS    0F
         LTORG
* Function __txvols page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
