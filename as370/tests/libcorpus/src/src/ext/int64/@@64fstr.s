         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_from_string'
* Program text area
@@LC0    EQU   *
         DC    C'0x'
         DC    X'0'
@@LC1    EQU   *
         DC    C'0123456789abcdef'
         DC    X'0'
@@LC2    EQU   *
         DC    C'0b'
         DC    X'0'
@@LC3    EQU   *
         DC    C'01'
         DC    X'0'
@@LC4    EQU   *
         DC    C'0123456789'
         DC    X'0'
         DS    0F
* X-func *@@64FSTR prologue
@@64FSTR PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64FSTR code
         L     5,0(11)
         L     4,4(11)
@@L18    EQU   *
         CLI   0(4),64
         BNE   @@L16
         A     4,=F'1'
         B     @@L18
@@L16    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC0)
         CLC   0(2,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L5
         L     6,=A(@@LC1)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(@@64FI32)
         BALR  14,15
         A     4,=F'2'
         B     @@L6
@@L5     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC2)
         CLC   0(2,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LA    3,104(,13)
         LTR   2,2
         BNE   @@L7
         L     6,=A(@@LC3)
         ST    3,88(13)
         MVC   92(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@64FI32)
         BALR  14,15
         A     4,=F'1'
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         L     6,=A(@@LC4)
         ST    3,88(13)
         MVC   92(4,13),=F'10'
         LA    1,88(,13)
         L     15,=V(@@64FI32)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L1
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L1
@@L14    EQU   *
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    2,0(2,3)
         ST    6,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L1
         SR    2,6
         SLL   2,16
         SRA   2,16
         ST    5,88(13)
         LA    3,104(,13)
         ST    3,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MUL)
         BALR  14,15
         AH    2,6(5)
         STH   2,6(5)
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BNE   @@L14
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64FSTR epilogue
         PDPEPIL
* Function *@@64FSTR literal pool
         DS    0F
         LTORG
* Function *@@64FSTR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
