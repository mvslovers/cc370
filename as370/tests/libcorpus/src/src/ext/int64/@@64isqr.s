         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_isqrt'
* Program text area
         DS    0F
* X-func *@@64ISQR prologue
@@64ISQR PDPPRLG CINDEX=0,FRAME=136,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64ISQR code
         L     6,0(11)
         L     7,4(11)
         LTR   6,6
         BE    @@L1
         LTR   7,7
         BE    @@L1
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         ST    6,88(13)
         LA    2,112(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         ST    2,88(13)
         LA    2,120(,13)
         ST    2,92(13)
         MVC   96(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@64RSFT)
         BALR  14,15
         B     @@L8
@@L7     EQU   *
         LA    3,120(,13)
         ST    3,88(13)
         ST    3,92(13)
         LA    2,128(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MUL)
         BALR  14,15
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         LTR   15,15
         BNH   @@L5
         ST    3,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@64DEC)
         BALR  14,15
         B     @@L6
@@L5     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         LA    2,112(,13)
         ST    2,88(13)
         LA    3,104(,13)
         ST    3,92(13)
         LA    2,120(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SUB)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64RSH1)
         BALR  14,15
         ST    3,88(13)
         ST    2,92(13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64ADD)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INC)
         BALR  14,15
         LA    5,112(,13)
         ST    5,88(13)
         LA    4,104(,13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         LTR   15,15
         BH    @@L7
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64ISQR epilogue
         PDPEPIL
* Function *@@64ISQR literal pool
         DS    0F
         LTORG
* Function *@@64ISQR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
