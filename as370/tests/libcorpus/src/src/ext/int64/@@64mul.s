         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_mul'
* Program text area
@V1      EQU   *
         DC    C'__64_mul'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: *** x=%d is out of range ***'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s: a'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s: b'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s: i=%d, j=%d, k=%d, 0x%04X * 0x%04X intermedia'
         DC    C'te=%u'
         DC    X'0'
         DS    0F
* X-func *@@64MUL prologue
@@64MUL  PDPPRLG CINDEX=0,FRAME=152,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64MUL code
         SLR   4,4
         SLR   5,5
         L     2,0(11)
         LTR   2,2
         BE    @@L1
         L     3,4(11)
         LTR   3,3
         BE    @@L1
         L     8,8(11)
         LTR   8,8
         BE    @@L1
         LA    9,120(,13)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LA    7,3(0,0)
@@L13    EQU   *
         LA    2,128(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LA    6,3(0,0)
@@L12    EQU   *
         LR    3,7
         AR    3,6
         LA    15,2(0,0)
         CR    3,15
         BNH   @@L8
         LR    9,7
         AR    9,7
         LR    2,6
         AR    2,6
         ST    2,144(13)
         L     8,4(11)
         LH    2,0(2,8)
         N     2,=XL4'0000FFFF'
         L     8,0(11)
         LH    5,0(9,8)
         N     5,=XL4'0000FFFF'
         MR    4,2
         LTR   5,5
         BE    @@L8
         LA    8,6(0,0)
         SR    8,3
         LA    15,3(0,0)
         CLR   8,15
         BNH   @@L11
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),0(11)
         MVC   92(4,13),=F'8'
         MVC   96(4,13),=A(@@LC1)
         MVC   100(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTODUMPF)
         BALR  14,15
         MVC   88(4,13),4(11)
         MVC   92(4,13),=F'8'
         MVC   96(4,13),=A(@@LC2)
         MVC   100(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTODUMPF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@V1)
         ST    7,96(13)
         ST    6,100(13)
         ST    3,104(13)
         L     3,0(11)
         LH    2,0(9,3)
         N     2,=XL4'0000FFFF'
         ST    2,108(13)
         L     9,4(11)
         L     15,144(13)
         LH    2,0(15,9)
         N     2,=XL4'0000FFFF'
         ST    2,112(13)
         ST    5,116(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         LA    2,136(,13)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         ST    2,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@64LSHW)
         BALR  14,15
         ST    2,88(13)
         LA    2,128(,13)
         ST    2,92(13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64ADD)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         BCTR  6,0
         LTR   6,6
         BNL   @@L12
         LA    3,120(,13)
         ST    3,88(13)
         LA    2,128(,13)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64ADD)
         BALR  14,15
         BCTR  7,0
         LTR   7,7
         BNL   @@L13
         ST    3,88(13)
         MVC   92(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64MUL epilogue
         PDPEPIL
* Function *@@64MUL literal pool
         DS    0F
         LTORG
* Function *@@64MUL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
