         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_to_string'
* Program text area
@@LC0    EQU   *
         DC    C'0'
         DC    X'0'
         DS    XL48
@@LC1    EQU   *
         DC    C'0123456789'
         DC    X'0'
         DS    0F
* X-func *@@64TSTR prologue
@@64TSTR PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64TSTR code
         L     9,4(11)
         L     8,8(11)
         SLR   7,7
         LR    6,7
         L     2,=A(@@LC0)
         MVC   104(2,13),0(2)
         LA    4,106(,13)
         LA    5,48(0,0)
         LR    2,7
         LR    3,7
         MVCL  4,2
         LA    4,160(,13)
         ST    4,88(13)
         MVC   92(4,13),=F'10'
         LA    1,88(,13)
         L     15,=V(@@64FI32)
         BALR  14,15
         L     2,0(11)
         LTR   2,2
         BE    @@L1
         LTR   9,9
         BE    @@L1
         ST    2,88(13)
         LA    2,168(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         B     @@L3
@@L5     EQU   *
         ST    2,88(13)
         ST    4,92(13)
         ST    2,96(13)
         LA    2,176(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@64DMOD)
         BALR  14,15
         LH    3,182(13)
         N     3,=XL4'0000FFFF'
         L     2,=A(@@LC1)
         IC    2,0(3,2)
         STC   2,104(6,13)
         A     6,=F'1'
@@L3     EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64IS0)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         CR    6,8
         BL    @@L5
@@L4     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNE   @@L6
         CR    7,8
         BNL   @@L8
         MVI   0(9),240
         LA    7,1(0,0)
         B     @@L8
@@L6     EQU   *
         L     12,0(,10)
         BCTR  6,0
         LTR   6,6
         BL    @@L8
         CR    7,8
         BNL   @@L8
         LR    2,6
         AR    2,13
         A     2,=F'104'
@@L12    EQU   *
         IC    3,0(2)
         STC   3,0(7,9)
         BCTR  6,0
         BCTR  2,0
         A     7,=F'1'
         LTR   6,6
         BL    @@L8
         CR    7,8
         BL    @@L12
@@L8     EQU   *
         L     12,0(,10)
         CR    7,8
         BNL   @@L1
         SLR   2,2
         STC   2,0(7,9)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64TSTR epilogue
         PDPEPIL
* Function *@@64TSTR literal pool
         DS    0F
         LTORG
* Function *@@64TSTR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
