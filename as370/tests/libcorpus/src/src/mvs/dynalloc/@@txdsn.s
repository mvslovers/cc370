         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __txdsn prologue
@@TXDSN  PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txdsn code
         L     9,0(11)
         L     7,4(11)
         LA    8,1(0,0)
         LTR   7,7
         BE    @@L4
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
         LA    2,79(0,0)
         CLR   15,2
         BH    @@L4
         LA    4,104(,13)
         LR    5,15
         LR    2,7
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,104(13,15)
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L5
         MVI   0(15),0
         AR    2,8
         ST    2,88(13)
         MVC   92(4,13),=F'93'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L6
         MVI   0(15),0
@@L6     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         MVC   88(4,13),=F'3'
         ST    8,92(13)
         ST    15,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L4
         ST    9,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BNE   @@L11
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    6,15
@@L5     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'2'
         MVC   92(4,13),=F'1'
         ST    6,96(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L4
         ST    9,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    8,15
         LTR   15,15
         BE    @@L4
@@L11    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LR    15,8
* Function __txdsn epilogue
         PDPEPIL
* Function __txdsn literal pool
         DS    0F
         LTORG
* Function __txdsn page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
