         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'PS'
         DC    X'0'
@@LC1    EQU   *
         DC    C'TERMINAL_RECFM'
         DC    X'0'
@@LC2    EQU   *
         DC    C'V'
         DC    X'0'
@@LC3    EQU   *
         DC    C'TERMINAL_LRECL'
         DC    X'0'
@@LC4    EQU   *
         DC    C'4000'
         DC    X'0'
@@LC5    EQU   *
         DC    C'TERMINAL_BLKSIZE'
         DC    X'0'
@@LC6    EQU   *
         DC    C'SYSOUT_CLASS'
         DC    X'0'
@@LC7    EQU   *
         DC    C'recfm='
         DC    X'0'
@@LC8    EQU   *
         DC    C'recfm('
         DC    X'0'
@@LC9    EQU   *
         DC    C' ,)'
         DC    X'0'
@@LC10   EQU   *
         DC    C'SYSOUT_RECFM'
         DC    X'0'
@@LC11   EQU   *
         DC    C'lrecl='
         DC    X'0'
@@LC12   EQU   *
         DC    C'lrecl('
         DC    X'0'
@@LC13   EQU   *
         DC    C'SYSOUT_LRECL'
         DC    X'0'
@@LC14   EQU   *
         DC    C'255'
         DC    X'0'
@@LC15   EQU   *
         DC    C'blksize='
         DC    X'0'
@@LC16   EQU   *
         DC    C'blksize('
         DC    X'0'
@@LC17   EQU   *
         DC    C'SYSOUT_BLKSIZE'
         DC    X'0'
         DS    0F
* X-func __fpstar prologue
@@FPSTAR PDPPRLG CINDEX=0,FRAME=216,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpstar code
         L     7,0(11)
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    8,15
         SLR   15,15
         ST    15,208(13)
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    6,208(,13)
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         IC    2,32(8)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L4
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXTERM)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXPERM)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    6,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@TXORG)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L9
         L     4,=A(@@LC2)
@@L9     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRECF)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         MVC   88(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LTR   15,15
         BNE   @@L11
         L     15,=A(@@LC4)
@@L11    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXLREC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    4,88(13)
         MVC   92(4,13),=F'194'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L16
         MVC   88(4,13),=A(@@LC5)
         B     @@L43
@@L4     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSYSO)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    6,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@TXORG)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         LR    5,7
         A     5,=F'106'
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC7)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L19
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC8)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
@@L19    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L39
         LA    2,120(,13)
         ST    2,88(13)
         A     15,=F'6'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L21
@@L39    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    4,15
@@L21    EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L22
         L     4,=A(@@LC2)
@@L22    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRECF)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L24
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
@@L24    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L40
         LA    2,120(,13)
         ST    2,88(13)
         A     15,=F'6'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         BNE   @@L26
@@L40    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC13)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
@@L26    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L27
         L     15,=A(@@LC14)
@@L27    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXLREC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    4,88(13)
         MVC   92(4,13),=F'194'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L16
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC15)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L30
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC16)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
@@L30    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L41
         LA    2,120(,13)
         ST    2,88(13)
         A     15,=F'8'
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         BNE   @@L32
@@L41    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC17)
@@L43    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
@@L32    EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L16
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBKSZ)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
@@L16    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L3
         LR    2,15
         BCTR  2,0
         L     4,208(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),1
         MVI   98(13),64
         MVC   104(4,13),208(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         L     2,208(13)
         L     2,0(2)
         MVC   43(8,7),6(2)
         LH    4,40(7)
         O     4,=F'-32768'
         STH   4,40(7)
         IC    2,32(8)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L3
         O     4,=F'128'
         STH   4,40(7)
@@L3     EQU   *
         L     12,0(,10)
         L     2,208(13)
         LTR   2,2
         BE    @@L38
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L38    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __fpstar epilogue
         PDPEPIL
* Function __fpstar literal pool
         DS    0F
         LTORG
* Function __fpstar page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
