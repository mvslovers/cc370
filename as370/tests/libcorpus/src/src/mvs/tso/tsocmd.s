         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'tsocmd'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: Missing pgm pointer'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s: No PPA'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s: No CPPL'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s: No memory for CBUF'
         DC    X'0'
@@LC4    EQU   *
         DC    C'%s'
         DC    X'0'
@@LC5    EQU   *
         DC    C'%s %s'
         DC    X'0'
         DS    0F
* X-func tsocmd prologue
TSOCMD   PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tsocmd code
         L     9,0(11)
         MVC   120(4,13),=F'8'
         MVC   124(4,13),=F'0'
         SLR   8,8
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    7,15
         L     6,124(13)
         LA    4,104(,13)
         LA    5,16(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LTR   9,9
         BNE   @@L2
         MVC   88(4,13),=A(@@LC0)
         B     @@L15
@@L2     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L4
         MVC   88(4,13),=A(@@LC1)
@@L15    EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L13
@@L4     EQU   *
         L     12,0(,10)
         L     2,44(15)
         LTR   2,2
         BNE   @@L14
         MVC   88(4,13),=A(@@LC2)
         B     @@L15
@@L14    EQU   *
         L     12,0(,10)
         IC    2,0(9)
         CLM   2,1,=XL1'00'
         BE    @@L6
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LR    8,15
@@L6     EQU   *
         L     12,0(,10)
         L     2,4(11)
         LTR   2,2
         BE    @@L7
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L7
         MVC   88(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         ST    15,124(13)
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         L     2,124(13)
         AR    2,8
         A     2,=F'8'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L8
         MVC   88(4,13),=A(@@LC3)
         B     @@L15
@@L8     EQU   *
         L     12,0(,10)
         L     2,44(7)
         MVC   104(16,13),0(2)
         L     7,116(13)
         LR    3,7
         A     3,=F'12'
         LA    2,64(0,0)
         LA    4,8(0,0)
         
*** MEMSET ***
         LR    14,3           => target (s)
         LR    15,4           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,2            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         CLR   8,4
         BNH   @@L10
         LR    8,4
@@L10    EQU   *
         L     12,0(,10)
         LR    4,3
         LR    5,8
         LR    2,9
         LR    3,8
         MVCL  4,2
         MVC   0(2,6),=H'4'
         STH   8,2(6)
         IC    2,28(7)
         LR    3,6
         A     3,=F'4'
         L     4,124(13)
         LTR   4,4
         BNE   @@L11
         O     2,=F'-128'
         STC   2,28(7)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC4)
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         SLL   15,16
         SRA   15,16
         AH    15,0(6)
         STH   15,0(6)
         B     @@L12
@@L11    EQU   *
         L     12,0(,10)
         N     2,=F'127'
         STC   2,28(7)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC5)
         ST    9,96(13)
         MVC   100(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         SLL   15,16
         SRA   15,16
         AH    15,0(6)
         STH   15,0(6)
         LH    2,2(6)
         AH    2,=H'1'
         STH   2,2(6)
@@L12    EQU   *
         L     12,0(,10)
         ST    6,104(13)
         ST    9,88(13)
         MVC   92(4,13),=F'0'
         LA    2,104(,13)
         ST    2,96(13)
         LA    2,120(,13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(@@LINK)
         BALR  14,15
@@L3     EQU   *
         LTR   6,6
         BE    @@L13
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L13    EQU   *
         L     12,0(,10)
         L     15,120(13)
* Function tsocmd epilogue
         PDPEPIL
* Function tsocmd literal pool
         DS    0F
         LTORG
* Function tsocmd page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
