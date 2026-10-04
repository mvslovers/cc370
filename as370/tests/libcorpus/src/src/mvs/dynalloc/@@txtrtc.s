         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    C'C'
         DC    X'0'
         DS    XL5
         DC    X'13'
         DC    C'COMP'
         DC    X'0'
         DS    XL2
         DC    X'08'
         DC    C'E'
         DC    X'0'
         DS    XL5
         DC    X'23'
         DC    C'ET'
         DC    X'0'
         DS    XL4
         DC    X'2B'
         DC    C'NOCOMP'
         DC    X'0'
         DC    X'04'
         DC    C'T'
         DC    X'0'
         DS    XL5
         DC    X'3B'
         DC    X'0'
         DS    XL6
         DC    X'00'
* Program text area
         DS    0F
* X-func __txtrtc prologue
@@TXTRTC PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txtrtc code
         L     8,4(11)
         LA    9,1(0,0)
         LTR   8,8
         BE    @@L10
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L10
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
         MVC   88(4,13),=F'79'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         A     3,=A(@V1+7)
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
         A     3,=F'8'
         L     2,=A(@V1)
         IC    2,0(3,2)
         CLM   2,1,=XL1'00'
         BNE   @@L11
@@L10    EQU   *
         L     12,0(,10)
         LR    15,9
* Function __txtrtc epilogue
         PDPEPIL
* Function __txtrtc literal pool
         DS    0F
         LTORG
* Function __txtrtc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
