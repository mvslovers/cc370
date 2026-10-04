         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'selectex'
* Program text area
         DS    0F
* X-func *@@75SELX prologue
@@75SELX PDPPRLG CINDEX=0,FRAME=160,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75SELX code
         L     3,0(11)
         L     9,4(11)
         L     8,16(11)
         SLR   7,7
         LR    5,7
         LA    6,96(,13)
         XC    0(64,6),0(6)     clear __75 parameter list
         SLR   4,4
         LA    2,1(0,0)
         CR    3,2
         BNH   @@L3
         L     2,20(11)
         LTR   2,2
         BE    @@L4
         LA    2,20(,11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    7,15
@@L4     EQU   *
         L     12,0(,10)
         LR    2,3
         BCTR  2,0
         SLL   2,16
         O     2,=F'17'
         ST    2,124(13)
         MVC   128(4,13),=F'0'
         ST    3,132(13)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LR    2,3
         A     2,=F'31'
         BNL   @@L5
         A     2,=F'31'
@@L5     EQU   *
         L     12,0(,10)
         SRA   2,5
         SLL   2,2
         LTR   9,9
         BE    @@L6
         ST    2,100(13)
         ST    9,116(13)
         MVC   128(4,13),=F'1'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         L     3,8(11)
         LTR   3,3
         BE    @@L7
         ST    2,100(13)
         ST    3,116(13)
         MVC   128(4,13),=F'2'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         L     3,12(11)
         LTR   3,3
         BE    @@L8
         ST    2,100(13)
         ST    3,116(13)
         MVC   128(4,13),=F'3'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LTR   8,8
         BE    @@L13
         L     2,0(8)
         LR    5,2
         SLL   5,5
         SLL   2,6
         AR    5,2
         SRL   5,3
         L     2,4(8)
         LTR   2,2
         BE    @@L13
         LA    3,64(0,0)
         CR    2,3
         BNH   @@L11
         SRA   2,6
         AR    5,2
         B     @@L13
@@L11    EQU   *
         L     12,0(,10)
         A     5,=F'1'
@@L13    EQU   *
         L     12,0(,10)
         MVC   100(4,13),=F'0'
         MVC   128(4,13),=F'4'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         L     4,112(13)
         L     2,=F'-2'
         CLR   4,2
         BNE   @@L25
         MVC   112(4,13),=F'0'
         LTR   8,8
         BE    @@L16
         LTR   5,5
         BE    @@L25
         BCTR  5,0
@@L16    EQU   *
         L     12,0(,10)
         L     15,20(11)
         LTR   15,15
         BE    @@L18
         LTR   7,7
         BE    @@L19
         SLR   4,4
         CLR   4,7
         BNL   @@L18
         LR    3,15
@@L26    EQU   *
         L     15,0(3)
         LTR   15,15
         BE    @@L22
         L     2,0(15)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L25
@@L22    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         A     3,=F'4'
         CLR   4,7
         BL    @@L26
         B     @@L18
@@L19    EQU   *
         L     12,0(,10)
         L     2,0(15)
         LTR   2,2
         BE    @@L18
         LR    3,15
@@L34    EQU   *
         L     15,0(3)
         L     2,=F'-2147483648'
         CLR   15,2
         BE    @@L18
         L     2,0(15)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L25
         LTR   15,15
         BL    @@L18
         A     3,=F'4'
         L     2,0(3)
         LTR   2,2
         BNE   @@L34
@@L18    EQU   *
         STIMER WAIT,BINTVL==F'8'   0.08 seconds
         L     12,0(,10)
         B     @@L13
@@L25    EQU   *
         L     12,0(,10)
         L     4,112(13)
         L     3,=F'-1'
         CLR   4,3
         BNE   @@L35
         MVC   100(4,13),=F'0'
         LH    2,124(13)
         N     2,=XL4'0000FFFF'
         ST    2,128(13)
         MVC   124(4,13),=F'2'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),112(13)
@@L35    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L36
         MVC   100(4,13),=F'0'
         ST    9,120(13)
         MVC   128(4,13),=F'5'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L36    EQU   *
         L     12,0(,10)
         L     2,8(11)
         LTR   2,2
         BE    @@L37
         MVC   100(4,13),=F'0'
         ST    2,120(13)
         MVC   128(4,13),=F'6'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L37    EQU   *
         L     12,0(,10)
         L     3,12(11)
         LTR   3,3
         BE    @@L38
         MVC   100(4,13),=F'0'
         ST    3,120(13)
         MVC   128(4,13),=F'7'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L38    EQU   *
         L     12,0(,10)
         MVC   128(4,13),=F'8'
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,4
* Function *@@75SELX epilogue
         PDPEPIL
* Function *@@75SELX literal pool
         DS    0F
         LTORG
* Function *@@75SELX page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
