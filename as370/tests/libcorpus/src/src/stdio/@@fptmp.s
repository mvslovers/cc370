         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'PS'
         DC    X'0'
@@LC1    EQU   *
         DC    C'recfm='
         DC    X'0'
@@LC2    EQU   *
         DC    C'recfm('
         DC    X'0'
@@LC3    EQU   *
         DC    C' ,)'
         DC    X'0'
@@LC4    EQU   *
         DC    C'TEMP_RECFM'
         DC    X'0'
@@LC5    EQU   *
         DC    C'V'
         DC    X'0'
@@LC6    EQU   *
         DC    C'lrecl='
         DC    X'0'
@@LC7    EQU   *
         DC    C'lrecl('
         DC    X'0'
@@LC8    EQU   *
         DC    C'TEMP_LRECL'
         DC    X'0'
@@LC9    EQU   *
         DC    C'255'
         DC    X'0'
@@LC10   EQU   *
         DC    C'blksize='
         DC    X'0'
@@LC11   EQU   *
         DC    C'blksize('
         DC    X'0'
@@LC12   EQU   *
         DC    C'TEMP_BLKSIZE'
         DC    X'0'
@@LC13   EQU   *
         DC    C'space='
         DC    X'0'
@@LC14   EQU   *
         DC    C'TEMP_SPACE'
         DC    X'0'
@@LC15   EQU   *
         DC    C'CYL'
         DC    X'0'
@@LC16   EQU   *
         DC    C'TRK'
         DC    X'0'
@@LC17   EQU   *
         DC    C'VIO'
         DC    X'0'
         DS    0F
* X-func __fptmp prologue
@@FPTMP  PDPPRLG CINDEX=0,FRAME=216,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fptmp code
         L     7,0(11)
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
         L     14,=A(@@L3)
         BNER  14
         ST    6,88(13)
         A     7,=F'61'
         ST    7,92(13)
         A     7,=F'-61'
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L3)
         BNER  14
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXNEW)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L3)
         BNER  14
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCAT)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L3)
         BNER  14
         ST    6,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@TXORG)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L3)
         BNER  14
         LR    5,7
         A     5,=F'106'
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L8
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
@@L8     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L43
         LA    2,120(,13)
         ST    2,88(13)
         A     3,=F'6'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L10
@@L43    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    4,15
@@L10    EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L11
         L     4,=A(@@LC5)
@@L11    EQU   *
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
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L13
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC7)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
@@L13    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L44
         LA    2,120(,13)
         ST    2,88(13)
         A     3,=F'6'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LTR   15,15
         BNE   @@L15
@@L44    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC8)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
@@L15    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L16
         L     15,=A(@@LC9)
@@L16    EQU   *
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
         BE    @@L18
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L19
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
@@L19    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L20
         LA    2,120(,13)
         ST    2,88(13)
         A     3,=F'8'
         ST    3,92(13)
         A     3,=F'-8'
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
@@L20    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L21
         MVC   88(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    3,15
@@L21    EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L18
         ST    6,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBKSZ)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
@@L18    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC13)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L45
         LA    2,120(,13)
         ST    2,88(13)
         A     3,=F'6'
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    2,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L45
         ST    15,88(13)
         MVC   92(4,13),=F'93'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L45
         LR    5,2
         A     3,=F'1'
         MVI   0(3),0
         B     @@L27
@@L45    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC14)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    5,15
@@L27    EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L28
         ST    5,88(13)
         MVC   92(4,13),=F'77'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L29
         L     2,=A(@@LC15)
         CLC   0(3,5),0(2)
         LA    4,1(0,0)
         BH    *+12
         BL    *+6
         SLR   4,4
         LNR   4,4
         LTR   4,4
         BNE   @@L30
         LA    2,208(,13)
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCYL)
         BALR  14,15
         B     @@L31
@@L30    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC16)
         CLC   0(3,5),0(2)
         LA    15,1(0,0)
         BH    *+12
         BL    *+6
         SLR   15,15
         LNR   15,15
         LA    2,208(,13)
         LTR   15,15
         BNE   @@L32
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXTRK)
         BALR  14,15
         B     @@L31
@@L32    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBLK)
         BALR  14,15
@@L31    EQU   *
         L     12,0(,10)
         LR    5,6
         A     5,=F'1'
@@L29    EQU   *
         L     12,0(,10)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L35
         N     2,=XL4'000000FF'
         L     3,=V(@@ISBUF)
         L     3,0(3)
@@L46    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BNE   @@L35
         A     5,=F'1'
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L35
         N     2,=XL4'000000FF'
         B     @@L46
@@L35    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSPAC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
@@L28    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC17)
         LA    1,88(,13)
         L     15,=V(@@TXUNIT)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
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
         OC    40(2,7),=H'-32768'
@@L3     EQU   *
         L     12,0(,10)
         L     2,208(13)
         LTR   2,2
         BE    @@L41
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L41    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __fptmp epilogue
         PDPEPIL
* Function __fptmp literal pool
         DS    0F
         LTORG
* Function __fptmp page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
