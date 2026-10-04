         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_div'
* Program text area
         DS    0F
* X-func *@@64DIV prologue
@@64DIV  PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64DIV code
         L     4,0(11)
         L     2,4(11)
         L     5,8(11)
         LTR   4,4
         BE    @@L1
         LTR   2,2
         BE    @@L1
         LTR   5,5
         BE    @@L1
         LA    6,104(,13)
         ST    6,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@64FI32)
         BALR  14,15
         ST    2,88(13)
         LA    2,112(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         ST    4,88(13)
         LA    2,120(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@64COPY)
         BALR  14,15
         B     @@L3
@@L6     EQU   *
         LH    2,112(13)
         CH    2,=H'0'
         BL    @@L7
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@64LSH1)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64LSH1)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LA    3,112(,13)
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         LA    2,1(0,0)
         CLR   15,2
         BNE   @@L6
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64RSH1)
         BALR  14,15
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64RSH1)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         B     @@L8
@@L11    EQU   *
         LA    2,120(,13)
         ST    2,88(13)
         LA    3,112(,13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@64CMP)
         BALR  14,15
         L     6,=F'-1'
         CLR   15,6
         BE    @@L10
         ST    2,88(13)
         ST    3,92(13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SUB)
         BALR  14,15
         ST    5,88(13)
         ST    4,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64OR)
         BALR  14,15
@@L10    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@64RSH1)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64RSH1)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LA    4,104(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@64IS0)
         BALR  14,15
         LTR   15,15
         BE    @@L11
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64DIV epilogue
         PDPEPIL
* Function *@@64DIV literal pool
         DS    0F
         LTORG
* Function *@@64DIV page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
