         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    C'BSAM'
         DC    X'0'
         DS    XL2
         DC    X'10'
         DC    C'TEST'
         DC    X'0'
         DS    XL2
         DC    X'10'
         DC    C'ABEND'
         DC    X'0'
         DS    XL1
         DC    X'20'
         DC    C'SKIP'
         DC    X'0'
         DS    XL2
         DC    X'40'
         DC    C'SKP'
         DC    X'0'
         DS    XL3
         DC    X'40'
         DC    C'ACCEPT'
         DC    X'0'
         DC    X'80'
         DC    X'0'
         DS    XL6
         DC    X'00'
* Program text area
         DS    0F
* X-func __txerop prologue
@@TXEROP PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txerop code
         L     5,4(11)
         LA    6,1(0,0)
         LTR   5,5
         BE    @@L8
         L     4,=A(@V1)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L8
         SLR   3,3
@@L9     EQU   *
         LR    2,3
         A     2,=A(@V1)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LTR   15,15
         BNE   @@L5
         MVC   88(4,13),=F'61'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         A     3,=A(@V1+7)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L8
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    6,15
         B     @@L8
@@L5     EQU   *
         L     12,0(,10)
         A     3,=F'8'
         IC    2,0(4,3)
         CLM   2,1,=XL1'00'
         BNE   @@L9
@@L8     EQU   *
         L     12,0(,10)
         LR    15,6
* Function __txerop epilogue
         PDPEPIL
* Function __txerop literal pool
         DS    0F
         LTORG
* Function __txerop page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
