         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'DATASET_RECFM'
         DC    X'0'
@@LC1    EQU   *
         DC    C'DATASET_LRECL'
         DC    X'0'
@@LC2    EQU   *
         DC    C'DATASET_BLKSIZE'
         DC    X'0'
@@LC3    EQU   *
         DC    C'DATASET_SPACE'
         DC    X'0'
@@LC4    EQU   *
         DC    C'DATASET_UNIT'
         DC    X'0'
@@LC5    EQU   *
         DC    C'DATASET_VOLSER'
         DC    X'0'
@@LC6    EQU   *
         DC    C';'
         DC    X'0'
@@LC7    EQU   *
         DC    C'RECFM='
         DC    X'0'
@@LC8    EQU   *
         DC    C'LRECL='
         DC    X'0'
@@LC9    EQU   *
         DC    C'BLKSIZE='
         DC    X'0'
@@LC10   EQU   *
         DC    C'SPACE='
         DC    X'0'
@@LC11   EQU   *
         DC    C'UNIT='
         DC    X'0'
@@LC12   EQU   *
         DC    C'VOLSER='
         DC    X'0'
@@LC13   EQU   *
         DC    C'MOUNT'
         DC    X'0'
@@LC14   EQU   *
         DC    C'PS'
         DC    X'0'
@@LC15   EQU   *
         DC    C'V'
         DC    X'0'
@@LC16   EQU   *
         DC    C'255'
         DC    X'0'
@@LC17   EQU   *
         DC    C'CYL='
         DC    X'0'
@@LC18   EQU   *
         DC    C'TRK='
         DC    X'0'
         DS    0F
* X-func __fpnew prologue
@@FPNEW  PDPPRLG CINDEX=0,FRAME=232,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fpnew code
         L     7,0(11)
         SLR   2,2
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    9,15
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         ST    15,212(13)
         MVC   88(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         ST    15,216(13)
         MVC   88(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LR    6,15
         MVC   88(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         ST    15,220(13)
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         ST    15,224(13)
         ST    2,228(13)
         ST    2,208(13)
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    3,2
         MVCL  4,2
         LA    8,120(,13)
         LA    2,86(0,0)
         L     3,228(13)
         
*** MEMSET ***
         LR    14,8           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    8,88(13)
         A     7,=F'106'
         ST    7,92(13)
         A     7,=F'-106'
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         LR    4,8
@@L77    EQU   *
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L71
         CLI   0(4),77
         BNE   @@L6
         L     2,=F'-1'
         IC    2,0(2,4)
         CLM   2,1,=XL1'7E'
         BE    @@L7
         MVI   0(4),126
         B     @@L8
@@L76    EQU   *
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         A     4,=F'1'
         ST    4,92(13)
         BCTR  4,0
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
@@L8     EQU   *
         L     12,0(,10)
         A     4,=F'1'
@@L78    EQU   *
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L6
         IC    2,0(4)
         LR    5,4
         A     5,=F'1'
         CLM   2,1,=XL1'5D'
         BE    @@L76
         N     2,=XL4'000000FF'
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
         LR    4,5
         B     @@L78
@@L6     EQU   *
         L     12,0(,10)
         IC    2,0(4)
         CLM   2,1,=XL1'6B'
         BNE   @@L14
         MVI   0(4),94
         B     @@L5
@@L14    EQU   *
         L     12,0(,10)
         N     2,=XL4'000000FF'
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
@@L5     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L77
@@L71    EQU   *
         L     12,0(,10)
         ST    8,88(13)
@@L79    EQU   *
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L74
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC7)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L20
         LR    9,4
         A     9,=F'6'
         B     @@L19
@@L20    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC8)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L22
         A     4,=F'6'
         ST    4,212(13)
         B     @@L19
@@L22    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L24
         A     4,=F'8'
         ST    4,216(13)
         B     @@L19
@@L24    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L26
         LR    6,4
         A     6,=F'6'
         B     @@L19
@@L26    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L28
         A     4,=F'5'
         ST    4,220(13)
         B     @@L19
@@L28    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L30
         A     4,=F'7'
         ST    4,224(13)
         B     @@L19
@@L30    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC13)
         CLC   0(6,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L19
         MVC   228(4,13),=F'1'
@@L19    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         B     @@L79
@@L74    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L35)
         BNER  14
         ST    2,88(13)
         A     7,=F'61'
         ST    7,92(13)
         A     7,=F'-61'
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L35)
         BNER  14
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXNEW)
         BALR  14,15
         LR    3,15
         LTR   15,15
         L     14,=A(@@L35)
         BNER  14
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCAT)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC14)
         LA    1,88(,13)
         L     15,=V(@@TXORG)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
         LTR   9,9
         BNE   @@L40
         L     9,=A(@@LC15)
@@L40    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRECF)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
         L     4,212(13)
         LTR   4,4
         BNE   @@L42
         MVC   212(4,13),=A(@@LC16)
@@L42    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),212(13)
         LA    1,88(,13)
         L     15,=V(@@TXLREC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
         ST    9,88(13)
         MVC   92(4,13),=F'194'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L44
         L     4,216(13)
         LTR   4,4
         BE    @@L44
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBKSZ)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
@@L44    EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L47
         L     2,=A(@@LC17)
         CLC   0(4,6),0(2)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L48
         LA    2,208(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCYL)
         BALR  14,15
         B     @@L80
@@L48    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC18)
         CLC   0(4,6),0(2)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L50
         LA    2,208(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXTRK)
         BALR  14,15
@@L80    EQU   *
         L     12,0(,10)
         A     6,=F'4'
         B     @@L49
@@L50    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'126'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L52
         MVI   0(15),0
@@L52    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBLK)
         BALR  14,15
         LTR   3,3
         BE    @@L49
         LR    6,3
         A     6,=F'1'
@@L49    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L55
         N     2,=XL4'000000FF'
         L     3,=V(@@ISBUF)
         L     3,0(3)
@@L81    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BNE   @@L55
         A     6,=F'1'
         IC    2,0(6)
         CLM   2,1,=XL1'00'
         BE    @@L55
         N     2,=XL4'000000FF'
         B     @@L81
@@L55    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSPAC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
@@L47    EQU   *
         L     12,0(,10)
         LH    2,40(7)
         N     2,=F'64'
         LTR   2,2
         BE    @@L58
         IC    2,52(7)
         CLM   2,1,=XL1'00'
         BNE   @@L58
         LA    2,208(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@TXRLSE)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
@@L58    EQU   *
         L     12,0(,10)
         L     2,220(13)
         LTR   2,2
         BE    @@L60
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BE    @@L60
         LA    2,208(,13)
         ST    2,88(13)
         MVC   92(4,13),220(13)
         LA    1,88(,13)
         L     15,=V(@@TXUNIT)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
@@L60    EQU   *
         L     12,0(,10)
         L     4,224(13)
         LTR   4,4
         BE    @@L62
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L62
         LA    2,208(,13)
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXVOLS)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
@@L62    EQU   *
         L     12,0(,10)
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L35
         BCTR  2,0
         L     4,208(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),1
         MVI   98(13),64
         L     2,220(13)
         LTR   2,2
         BE    @@L67
         IC    2,0(2)
         CLM   2,1,=XL1'00'
         BNE   @@L66
@@L67    EQU   *
         L     12,0(,10)
         L     3,224(13)
         LTR   3,3
         BE    @@L65
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L65
@@L66    EQU   *
         L     12,0(,10)
         L     4,228(13)
         LTR   4,4
         BNE   @@L65
         OI    98(13),32
@@L65    EQU   *
         L     12,0(,10)
         MVC   104(4,13),208(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L35
         L     2,208(13)
         L     2,0(2)
         MVC   43(8,7),6(2)
         OC    40(2,7),=H'-32768'
@@L35    EQU   *
         L     12,0(,10)
         L     2,208(13)
         LTR   2,2
         BE    @@L69
         LA    2,208(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L69    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __fpnew epilogue
         PDPEPIL
* Function __fpnew literal pool
         DS    0F
         LTORG
* Function __fpnew page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
