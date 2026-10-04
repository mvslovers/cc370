         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'NE'
         DC    X'0'
@@LC1    EQU   *
         DC    C'OL'
         DC    X'0'
@@LC2    EQU   *
         DC    C'PG'
         DC    X'0'
@@LC3    EQU   *
         DC    C'RF'
         DC    X'0'
@@LC4    EQU   *
         DC    C'RN'
         DC    X'0'
@@LC5    EQU   *
         DC    C'RU'
         DC    X'0'
@@LC6    EQU   *
         DC    C'OV'
         DC    X'0'
@@LC7    EQU   *
         DC    C'TS'
         DC    X'0'
@@LC8    EQU   *
         DC    C'%06X'
         DC    X'0'
@@LC9    EQU   *
         DC    C'%02X%02X%02X'
         DC    X'0'
@@LC10   EQU   *
         DC    C'%02X'
         DC    X'0'
@@LC11   EQU   *
         DC    C'00'
         DC    X'0'
@@LC12   EQU   *
         DC    C'  '
         DC    X'0'
@@LC13   EQU   *
         DC    C'%s %s %s %s %s %s %s %s'
         DC    X'0'
@@LC14   EQU   *
         DC    C'%02X%02X%02X%02X'
         DC    X'0'
         DS    0F
* X-func __fmtloa prologue
@@FMTLOA PDPPRLG CINDEX=0,FRAME=208,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fmtloa code
         L     6,0(11)
         L     3,4(11)
         L     15,=F'-1'
         LR    5,6
         A     5,=F'12'
         LTR   6,6
         BNE   @@L3
         LR    5,6
@@L3     EQU   *
         L     12,0(,10)
         SLR   7,7
         LR    9,7
         LR    8,7
         ST    7,168(13)
         MVC   172(4,13),=A(@@LC0)
         MVC   176(4,13),=A(@@LC1)
         MVC   180(4,13),=A(@@LC2)
         MVC   184(4,13),=A(@@LC3)
         MVC   188(4,13),=A(@@LC4)
         MVC   192(4,13),=A(@@LC5)
         MVC   196(4,13),=A(@@LC6)
         MVC   200(4,13),=A(@@LC7)
         LTR   5,5
         BE    @@L5
         LTR   3,3
         BE    @@L5
         LA    2,75(0,0)
         
*** MEMSET ***
         LR    14,3           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,7            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         LR    4,7
         CLI   0(6),64
         BNH   @@L9
         LR    2,6
@@L11    EQU   *
         IC    15,0(2)
         STC   15,0(4,3)
         A     4,=F'1'
         A     2,=F'1'
         LA    15,7(0,0)
         CR    4,15
         BH    @@L9
         CLI   0(2),64
         BH    @@L11
@@L9     EQU   *
         L     12,0(,10)
         A     3,=F'9'
         ST    3,88(13)
         A     3,=F'-9'
         MVC   92(4,13),=A(@@LC8)
         L     2,8(6)
         SRL   2,8
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         IC    4,11(6)
         LR    15,4
         N     15,=F'31'
         AR    15,15
         BE    @@L5
         IC    2,8(5)
         N     2,=F'4'
         LTR   2,2
         BE    @@L13
         LR    9,5
         A     9,=F'21'
@@L13    EQU   *
         L     12,0(,10)
         SLL   4,24
         SRA   4,24
         C     4,=F'0'
         BNL   @@L14
         LR    7,9
         A     7,=F'8'
         LTR   9,9
         BNE   @@L14
         LR    7,5
         A     7,=F'21'
@@L14    EQU   *
         L     12,0(,10)
         IC    4,18(5)
         LR    2,4
         N     2,=F'16'
         LTR   2,2
         BE    @@L17
         LR    8,7
         A     8,=F'11'
         LTR   7,7
         BNE   @@L19
         LR    8,9
         A     8,=F'8'
         LTR   9,9
         BNE   @@L19
         LR    8,5
         A     8,=F'21'
@@L19    EQU   *
         L     12,0(,10)
         A     8,=F'1'
         N     8,=F'2147483646'
@@L17    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=F'8'
         LTR   2,2
         BE    @@L22
         LR    2,8
         A     2,=F'4'
         ST    2,168(13)
         LTR   8,8
         BNE   @@L22
         LR    4,7
         A     4,=F'11'
         ST    4,168(13)
         LTR   7,7
         BNE   @@L22
         LR    6,9
         A     6,=F'8'
         ST    6,168(13)
         LTR   9,9
         BNE   @@L22
         LR    15,5
         A     15,=F'21'
         ST    15,168(13)
@@L22    EQU   *
         L     12,0(,10)
         A     3,=F'16'
         ST    3,88(13)
         A     3,=F'-16'
         MVC   92(4,13),=A(@@LC9)
         SLR   2,2
         IC    2,10(5)
         ST    2,96(13)
         SLR   2,2
         IC    2,11(5)
         ST    2,100(13)
         SLR   2,2
         IC    2,12(5)
         ST    2,104(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LTR   7,7
         BE    @@L29
         SLR   4,4
         CLI   3(7),64
         BNH   @@L29
         LR    2,7
         A     2,=F'3'
         LR    15,3
         A     15,=F'23'
@@L33    EQU   *
         MVC   0(1,15),0(2)
         A     4,=F'1'
         A     15,=F'1'
         A     2,=F'1'
         LA    6,7(0,0)
         CR    4,6
         BH    @@L29
         CLI   0(2),64
         BH    @@L33
@@L29    EQU   *
         L     12,0(,10)
         L     15,168(13)
         LTR   15,15
         BE    @@L34
         A     3,=F'32'
         ST    3,88(13)
         A     3,=F'-32'
         MVC   92(4,13),=A(@@LC10)
         SLR   2,2
         IC    2,1(15)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         B     @@L35
@@L34    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC11)
         MVC   32(3,3),0(2)
@@L35    EQU   *
         L     12,0(,10)
         A     3,=F'35'
         ST    3,88(13)
         A     3,=F'-35'
         MVC   92(4,13),=A(@@LC9)
         SLR   2,2
         IC    2,15(5)
         ST    2,96(13)
         SLR   2,2
         IC    2,16(5)
         ST    2,100(13)
         SLR   2,2
         IC    2,17(5)
         ST    2,104(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         IC    4,8(5)
         LR    15,4
         N     15,=XL4'000000FF'
         LR    2,15
         N     2,=F'2'
         LTR   2,2
         BE    @@L36
         MVC   172(4,13),=A(@@LC12)
@@L36    EQU   *
         L     12,0(,10)
         LR    2,15
         N     2,=F'8'
         LTR   2,2
         BNE   @@L37
         MVC   176(4,13),=A(@@LC12)
@@L37    EQU   *
         L     12,0(,10)
         IC    2,18(5)
         N     2,=F'32'
         LTR   2,2
         BNE   @@L38
         MVC   180(4,13),=A(@@LC12)
@@L38    EQU   *
         L     12,0(,10)
         IC    2,9(5)
         N     2,=F'1'
         LTR   2,2
         BNE   @@L39
         MVC   184(4,13),=A(@@LC12)
@@L39    EQU   *
         L     12,0(,10)
         SLL   4,24
         SRA   4,24
         C     4,=F'0'
         BL    @@L40
         MVC   188(4,13),=A(@@LC12)
@@L40    EQU   *
         L     12,0(,10)
         LR    2,15
         N     2,=F'64'
         LTR   2,2
         BNE   @@L41
         MVC   192(4,13),=A(@@LC12)
@@L41    EQU   *
         L     12,0(,10)
         LR    2,15
         N     2,=F'32'
         LTR   2,2
         BNE   @@L42
         MVC   196(4,13),=A(@@LC12)
@@L42    EQU   *
         L     12,0(,10)
         N     15,=F'16'
         LTR   15,15
         BNE   @@L43
         MVC   200(4,13),=A(@@LC12)
@@L43    EQU   *
         L     12,0(,10)
         A     3,=F'42'
         ST    3,88(13)
         A     3,=F'-42'
         MVC   92(4,13),=A(@@LC13)
         MVC   96(4,13),172(13)
         MVC   100(4,13),176(13)
         MVC   104(4,13),180(13)
         MVC   108(4,13),184(13)
         MVC   112(4,13),188(13)
         MVC   116(4,13),192(13)
         MVC   120(4,13),196(13)
         MVC   124(4,13),200(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         LTR   8,8
         BE    @@L44
         A     3,=F'66'
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC14)
         SLR   2,2
         IC    2,0(8)
         ST    2,96(13)
         SLR   2,2
         IC    2,1(8)
         ST    2,100(13)
         SLR   2,2
         IC    2,2(8)
         ST    2,104(13)
         SLR   2,2
         IC    2,3(8)
         ST    2,108(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L44    EQU   *
         L     12,0(,10)
         SLR   15,15
@@L5     EQU   *
         L     12,0(,10)
* Function __fmtloa epilogue
         PDPEPIL
* Function __fmtloa literal pool
         DS    0F
         LTORG
* Function __fmtloa page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
