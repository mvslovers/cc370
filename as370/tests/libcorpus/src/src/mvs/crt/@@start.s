         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'*SYSPRINT'
         DC    X'0'
@@LC1    EQU   *
         DC    C'w'
         DC    X'0'
@@LC2    EQU   *
         DC    C'*SYSTERM'
         DC    X'0'
@@LC3    EQU   *
         DC    C'SYSTERM DD not defined'
         DC    X'0'
@@LC4    EQU   *
         DC    C'dd:SYSIN'
         DC    X'0'
@@LC5    EQU   *
         DC    C'r'
         DC    X'0'
@@LC6    EQU   *
         DC    C'''NULLFILE'''
         DC    X'0'
@@LC7    EQU   *
         DC    C'SYSIN DD not defined'
         DC    X'15'
         DC    X'0'
@@LC8    EQU   *
         DC    C'dd:SYSENV'
         DC    X'0'
@@LC9    EQU   *
         DC    C'dd:ENVIRON'
         DC    X'0'
         DS    0F
* X-func __start prologue
@@START  PDPPRLG CINDEX=0,FRAME=624,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __start code
         L     7,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    8,15
         MVC   616(4,13),=F'0'
         SLR   6,6
         IC    6,0(7)
         SLL   6,8
         SLR   2,2
         IC    2,1(7)
         OR    6,2
         LTR   6,6
         BNH   @@L2
         IC    2,2(7)
         CLM   2,1,=XL1'00'
         BNE   @@L2
         OI    10(15),64
         SLR   2,2
         IC    2,3(7)
         ST    2,616(13)
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    2,15
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         ST    2,0(15)
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         L     2,0(15)
         LTR   2,2
         BNE   @@L3
         MVC   88(4,13),=F'12'
         LA    1,88(,13)
         L     15,=V(@@EXITA)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    2,15
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         ST    2,0(15)
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         L     2,0(15)
         LTR   2,2
         BNE   @@L4
         MVC   88(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(PUTS)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         MVC   88(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         MVC   88(4,13),=F'12'
         LA    1,88(,13)
         L     15,=V(@@EXITA)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC4)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    2,15
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         ST    2,0(15)
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         L     2,0(15)
         LTR   2,2
         BNE   @@L5
         MVC   88(4,13),=A(@@LC6)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    2,15
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         ST    2,0(15)
@@L5     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         L     2,0(15)
         LTR   2,2
         BNE   @@L6
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         MVC   88(4,13),=A(@@LC7)
         MVC   92(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FPUTS)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         MVC   88(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         MVC   88(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         MVC   88(4,13),=F'12'
         LA    1,88(,13)
         L     15,=V(@@EXITA)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC8)
         LA    1,88(,13)
         L     15,=V(LOADENV)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         MVC   88(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(LOADENV)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(TZSET)
         BALR  14,15
         LA    3,307(0,0)
         CLR   6,3
         BNH   @@L8
         LR    6,3
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         LTR   6,6
         BNL   @@L9
         SLR   6,6
@@L9     EQU   *
         L     12,0(,10)
         LA    9,304(,13)
         SLR   2,2
         LA    3,310(0,0)
         
*** MEMSET ***
         LR    14,9           => target (s)
         LR    15,3           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,2            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         IC    2,10(8)
         N     2,=F'64'
         LTR   2,2
         BE    @@L11
         A     6,=F'-4'
         LR    4,9
         LR    5,6
         LR    2,7
         A     2,=F'4'
         B     @@L53
@@L11    EQU   *
         L     12,0(,10)
         LR    4,9
         LR    5,6
         LR    2,7
         A     2,=F'2'
@@L53    EQU   *
         L     12,0(,10)
         LR    3,6
         MVCL  4,2
         LR    7,9
         L     4,12(11)
         LTR   4,4
         BE    @@L13
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    6,15
         MVC   620(4,13),=F'0'
         IC    2,10(8)
         N     2,=F'64'
         LTR   2,2
         BE    @@L15
         LTR   15,15
         BE    @@L15
         L     3,28(15)
         LTR   3,3
         BE    @@L15
         L     2,0(4)
         LTR   2,2
         BL    @@L15
         L     2,4(4)
         LTR   2,2
         BL    @@L15
         L     2,8(4)
         N     2,=F'2147483647'
         N     3,=F'2147483647'
         CLR   2,3
         BNE   @@L15
         MVC   620(4,13),=F'1'
         LA    5,4(0,0)
         B     @@L16
@@L51    EQU   *
         SLR   15,15
         STC   15,0(4,3)
         B     @@L25
@@L15    EQU   *
         L     12,0(,10)
         LA    5,10(0,0)
@@L16    EQU   *
         L     12,0(,10)
         SLR   4,4
         CR    4,5
         BNL   @@L18
         L     3,12(11)
@@L21    EQU   *
         L     2,0(3)
         A     8,=F'76'
         ST    8,88(13)
         A     8,=F'-76'
         LR    15,2
         N     15,=F'2147483647'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   2,2
         BL    @@L18
         A     4,=F'1'
         A     3,=F'4'
         CR    4,5
         BL    @@L21
@@L18    EQU   *
         L     12,0(,10)
         L     2,620(13)
         LTR   2,2
         BE    @@L13
         MVC   44(4,6),12(11)
@@L13    EQU   *
         L     12,0(,10)
         IC    2,10(8)
         N     2,=F'64'
         LTR   2,2
         BE    @@L23
         ST    9,96(13)
         SLR   4,4
@@L28    EQU   *
         L     3,96(13)
         IC    2,0(4,3)
         SLL   2,24
         SRA   2,24
         C     2,=F'64'
         BE    @@L51
         A     4,=F'1'
         C     4,616(13)
         BNH   @@L28
@@L25    EQU   *
         L     12,0(,10)
         L     7,616(13)
         AR    7,9
         B     @@L29
@@L23    EQU   *
         L     12,0(,10)
         MVC   96(4,13),4(11)
         L     3,4(11)
         STC   2,8(3)
         MVC   88(4,13),4(11)
         MVC   92(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L29
         STC   2,0(15)
@@L29    EQU   *
         L     12,0(,10)
         CLI   0(7),64
         BNE   @@L47
         A     7,=F'1'
         B     @@L29
@@L47    EQU   *
         L     12,0(,10)
         LA    4,1(0,0)
         IC    2,0(7)
         CLM   2,1,=XL1'00'
         BE    @@L34
         LA    5,100(,13)
@@L43    EQU   *
         LA    2,64(0,0)
         IC    3,0(7)
         CLM   3,1,=XL1'7F'
         BNE   @@L37
         A     7,=F'1'
         LR    2,3
@@L37    EQU   *
         L     12,0(,10)
         ST    7,0(5)
         A     4,=F'1'
         A     5,=F'4'
         N     2,=XL4'000000FF'
         ST    7,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L34
         MVI   0(15),0
@@L54    EQU   *
         A     7,=F'1'
         CLI   0(7),64
         BE    @@L54
         IC    2,0(7)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L34
         LA    15,49(0,0)
         CR    4,15
         BNH   @@L43
@@L34    EQU   *
         L     12,0(,10)
         LR    2,4
         SLL   2,2
         SLR   3,3
         ST    3,96(13,2)
         ST    4,88(13)
         LA    2,96(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(MAIN)
         BALR  14,15
         LR    2,15
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@EXIT)
         BALR  14,15
         LR    15,2
* Function __start epilogue
         PDPEPIL
* Function __start literal pool
         DS    0F
         LTORG
* Function __start page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
