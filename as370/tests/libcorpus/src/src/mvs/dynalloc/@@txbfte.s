         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    C'DYNAMIC'
         DC    X'0'
         DS    XL1
         DC    X'08'
         DC    C'EXCHANGE'
         DC    X'0'
         DC    X'10'
         DC    C'RECORD'
         DC    X'0'
         DS    XL2
         DC    X'20'
         DC    C'SIMPLE'
         DC    X'0'
         DS    XL2
         DC    X'40'
         DC    C'AREA'
         DC    X'0'
         DS    XL4
         DC    X'60'
         DC    X'0'
         DS    XL8
         DC    X'00'
* Program text area
         DS    0F
* X-func __txbfte prologue
@@TXBFTE PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txbfte code
         MVC   104(4,13),=F'1'
         L     2,4(11)
         LTR   2,2
         BE    @@L10
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         SLR   9,9
         L     2,=A(@V1)
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L10
         LR    8,9
@@L11    EQU   *
         LR    3,8
         AR    3,9
         LR    6,3
         A     6,=A(@V1)
         LR    7,15
         L     4,4(11)
         LR    5,15
         LA    2,1(0,0)
         CLCL  6,4
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L7
         MVC   88(4,13),=F'47'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         A     3,=A(@V1+9)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L10
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         ST    15,104(13)
         B     @@L10
@@L7     EQU   *
         L     12,0(,10)
         A     9,=F'1'
         A     8,=F'9'
         LR    2,8
         AR    2,9
         L     3,=A(@V1)
         IC    2,0(2,3)
         CLM   2,1,=XL1'00'
         BNE   @@L11
@@L10    EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function __txbfte epilogue
         PDPEPIL
* Function __txbfte literal pool
         DS    0F
         LTORG
* Function __txbfte page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
