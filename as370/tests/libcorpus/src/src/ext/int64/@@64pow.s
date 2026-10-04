         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_pow'
* Program text area
         DS    0F
* X-func *@@64POW prologue
@@64POW  PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64POW code
         L     5,0(11)
         L     2,4(11)
         L     3,8(11)
         LTR   5,5
         BE    @@L1
         LTR   2,2
         BE    @@L1
         LTR   3,3
         BE    @@L1
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INC)
         BALR  14,15
         B     @@L1
@@L3     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         LA    2,104(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         ST    5,88(13)
         LA    6,112(,13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64DEC)
         BALR  14,15
         B     @@L5
@@L7     EQU   *
         ST    2,88(13)
         ST    5,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MUL)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@64DEC)
         BALR  14,15
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         LA    4,104(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@64IS0)
         BALR  14,15
         LA    2,112(,13)
         LTR   15,15
         BE    @@L7
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64POW epilogue
         PDPEPIL
* Function *@@64POW literal pool
         DS    0F
         LTORG
* Function *@@64POW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
