         COPY  PDPTOP
         CSECT
* Program data area
@V1      EQU   *
         DC    X'D4'
         DC    X'02'
         DC    X'D9'
         DC    X'02'
         DC    X'C1'
         DC    X'04'
         DC    X'C7'
         DC    X'04'
         DC    X'E2'
         DC    X'08'
         DC    X'C2'
         DC    X'10'
         DC    X'C4'
         DC    X'20'
         DC    X'E3'
         DC    X'20'
         DC    X'E5'
         DC    X'40'
         DC    X'C6'
         DC    X'80'
         DC    X'E4'
         DC    X'C0'
         DC    X'00'
         DC    X'00'
* Program text area
         DS    0F
* X-func __txrecf prologue
@@TXRECF PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __txrecf code
         L     15,4(11)
         LA    7,1(0,0)
         LTR   15,15
         BE    @@L13
         MVI   104(13),0
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L16
         LR    3,15
@@L11    EQU   *
         IC    6,0(3)
         O     6,=F'64'
         L     5,=A(@V1)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L7
         L     4,=A(@V1+1)
         SLR   15,15
@@L10    EQU   *
         IC    5,0(15,5)
         STC   5,80(,13)
         CLM   6,1,80(13)
         BNE   @@L8
         OC    104(1,13),0(4)
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         A     15,=F'2'
         A     4,=F'2'
         L     5,=A(@V1)
         IC    2,0(15,5)
         CLM   2,1,=XL1'00'
         BNE   @@L10
@@L7     EQU   *
         L     12,0(,10)
         A     3,=F'1'
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L11
@@L16    EQU   *
         L     12,0(,10)
         CLI   104(13),0
         BE    @@L13
         MVC   88(4,13),=F'73'
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'1'
         LA    2,104(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@NWTX99)
         BALR  14,15
         LTR   15,15
         BE    @@L13
         MVC   88(4,13),0(11)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    7,15
@@L13    EQU   *
         L     12,0(,10)
         LR    15,7
* Function __txrecf epilogue
         PDPEPIL
* Function __txrecf literal pool
         DS    0F
         LTORG
* Function __txrecf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
