         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'L'
         DC    X'0'
         DS    0F
* X-func __txbufo prologue
@@TXBUFO PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txbufo code
         L     3,4(11)
         LA    4,1(0,0)
         LR    15,3
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         ST    15,104(13)
         LTR   15,15
         BNE   @@L4
         LTR   3,3
         BE    @@L4
         L     2,=A(@@LC0)
         CLC   0(2,3),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L4
         MVC   104(4,13),=F'128'
@@L4     EQU   *
         L     12,0(,10)
         L     2,104(13)
         LA    3,99(0,0)
         CLR   2,3
         BNH   @@L7
         LA    3,128(0,0)
         CLR   2,3
         BNE   @@L9
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'53'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         LA    2,107(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L9
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    4,15
@@L9     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __txbufo epilogue
         PDPEPIL
* Function __txbufo literal pool
         DS    0F
         LTORG
* Function __txbufo page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
