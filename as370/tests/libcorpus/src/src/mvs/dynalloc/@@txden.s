         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    C'200'
         DC    X'0'
         DS    XL1
         DC    X'03'
         DC    C'556'
         DC    X'0'
         DS    XL1
         DC    X'43'
         DC    C'800'
         DC    X'0'
         DS    XL1
         DC    X'83'
         DC    C'1600'
         DC    X'0'
         DC    X'C3'
         DC    C'6250'
         DC    X'0'
         DC    X'D3'
         DC    X'0'
         DS    XL4
         DC    X'00'
* Program text area
         DS    0F
* X-func __txden prologue
@@TXDEN  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txden code
         L     7,4(11)
         LA    8,1(0,0)
         LTR   7,7
         BE    @@L8
         SLR   5,5
         L     6,=A(@V1)
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L8
         LR    4,5
@@L9     EQU   *
         LR    3,4
         AR    3,5
         LR    2,3
         A     2,=A(@V1)
         ST    2,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(STRCMP)
         BALR  14,15
         LTR   15,15
         BNE   @@L5
         MVC   88(4,13),=F'59'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         A     3,=A(@V1+5)
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
         LR    8,15
         B     @@L8
@@L5     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         A     4,=F'5'
         LR    2,4
         AR    2,5
         IC    2,0(2,6)
         CLM   2,1,=XL1'00'
         BNE   @@L9
@@L8     EQU   *
         L     12,0(,10)
         LR    15,8
* Function __txden epilogue
         PDPEPIL
* Function __txden literal pool
         DS    0F
         LTORG
* Function __txden page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
