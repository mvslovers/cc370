         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    C'NL'
         DC    X'0'
         DS    XL1
         DC    X'01'
         DC    C'SL'
         DC    X'0'
         DS    XL1
         DC    X'02'
         DC    C'NSL'
         DC    X'0'
         DC    X'04'
         DC    C'SUL'
         DC    X'0'
         DC    X'0A'
         DC    C'BLP'
         DC    X'0'
         DC    X'10'
         DC    C'LTM'
         DC    X'0'
         DC    X'21'
         DC    C'AL'
         DC    X'0'
         DS    XL1
         DC    X'40'
         DC    C'AUL'
         DC    X'0'
         DC    X'48'
         DC    X'0'
         DS    XL3
         DC    X'00'
* Program text area
         DS    0F
* X-func __txlabe prologue
@@TXLABE PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txlabe code
         L     8,4(11)
         LA    9,1(0,0)
         LTR   8,8
         BE    @@L10
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         CR    15,9
         BNH   @@L10
         L     2,=A(@V1)
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L10
         SLR   3,3
@@L11    EQU   *
         LR    6,3
         A     6,=A(@V1)
         LR    7,15
         LR    4,8
         LR    5,15
         LA    2,1(0,0)
         CLCL  6,4
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L7
         MVC   88(4,13),=F'30'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         A     3,=A(@V1+4)
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
         LR    9,15
         B     @@L10
@@L7     EQU   *
         L     12,0(,10)
         A     3,=F'5'
         L     2,=A(@V1)
         IC    2,0(3,2)
         CLM   2,1,=XL1'00'
         BNE   @@L11
@@L10    EQU   *
         L     12,0(,10)
         LR    15,9
* Function __txlabe epilogue
         PDPEPIL
* Function __txlabe literal pool
         DS    0F
         LTORG
* Function __txlabe page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
