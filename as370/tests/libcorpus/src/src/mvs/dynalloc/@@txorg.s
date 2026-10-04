         COPY  PDPTOP
         CSECT
* Program data area
         DS    0H
@V1      EQU   *
         DC    C'CQ'
         DC    X'0'
         DS    XL3
         DC    X'0800'
         DC    C'CX'
         DC    X'0'
         DS    XL3
         DC    X'1000'
         DC    C'DA'
         DC    X'0'
         DS    XL3
         DC    X'2000'
         DC    C'DAU'
         DC    X'0'
         DS    XL2
         DC    X'2100'
         DC    C'GS'
         DC    X'0'
         DS    XL3
         DC    X'0080'
         DC    C'MQ'
         DC    X'0'
         DS    XL3
         DC    X'0400'
         DC    C'PO'
         DC    X'0'
         DS    XL3
         DC    X'0200'
         DC    C'POU'
         DC    X'0'
         DS    XL2
         DC    X'0300'
         DC    C'PS'
         DC    X'0'
         DS    XL3
         DC    X'4000'
         DC    C'PSU'
         DC    X'0'
         DS    XL2
         DC    X'4100'
         DC    C'TCAM'
         DC    X'0'
         DS    XL1
         DC    X'0004'
         DC    C'3705'
         DC    X'0'
         DS    XL1
         DC    X'0004'
         DC    C'TQ'
         DC    X'0'
         DS    XL3
         DC    X'0020'
         DC    C'TX'
         DC    X'0'
         DS    XL3
         DC    X'0040'
         DC    C'VSAM'
         DC    X'0'
         DS    XL1
         DC    X'0008'
         DC    X'0'
         DS    XL5
         DC    X'0000'
* Program text area
         DS    0F
* X-func __txorg prologue
@@TXORG  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txorg code
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
         MVC   88(4,13),=F'60'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'2'
         A     3,=A(@V1+6)
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
* Function __txorg epilogue
         PDPEPIL
* Function __txorg literal pool
         DS    0F
         LTORG
* Function __txorg page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
