         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'wb,recfm=vb,lrecl=133,blksize=32760'
         DC    X'0'
@@LC1    EQU   *
         DC    C'Unable to allocate tmpfile'
         DC    X'0'
@@LC2    EQU   *
         DC    X'0'
@@LC3    EQU   *
         DC    C' LISTC LEVEL(''%s'') OUTFILE(%s) %s'
         DC    X'0'
@@LC4    EQU   *
         DC    C'DD:%s'
         DC    X'0'
@@LC5    EQU   *
         DC    C'r,record'
         DC    X'0'
@@LC6    EQU   *
         DC    C'unable to reopen temp file'
         DC    X'0'
@@LC7    EQU   *
         DC    C'%s'
         DC    X'0'
         DS    0F
* X-func __listc prologue
@@LISTC  PDPPRLG CINDEX=0,FRAME=432,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __listc code
         L     9,4(11)
         SLR   2,2
         MVC   424(4,13),548(2)
         L     8,=F'-1'
         LR    6,2
         LA    4,104(,13)
         LA    5,12(0,0)
         LR    3,2
         MVCL  4,2
         LA    3,120(,13)
         LR    4,3
         LA    5,45(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LA    7,168(,13)
         LR    4,7
         LA    5,256(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LA    4,120(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(TMPNAM)
         BALR  14,15
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L2
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         NC    40(2,15),=H'32767'
         LA    2,104(,13)
         ST    2,88(13)
         A     6,=F'43'
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         LA    3,120(,13)
         ST    3,88(13)
         A     6,=F'18'
         ST    6,92(13)
         A     6,=F'-61'
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         SLR   6,6
         LTR   9,9
         BNE   @@L4
         L     9,=A(@@LC2)
@@L4     EQU   *
         L     12,0(,10)
         MVC   88(4,13),424(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),0(11)
         ST    2,96(13)
         ST    9,100(13)
         LA    1,88(,13)
         L     15,=V(IDCAMS)
         BALR  14,15
         MVC   88(4,13),424(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC4)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         ST    7,88(13)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L6
         L     8,=F'-1'
         MVC   88(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LA    4,120(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(REMOVE)
         BALR  14,15
         B     @@L3
@@L6     EQU   *
         L     12,0(,10)
         SLR   3,3
         LA    2,256(0,0)
         
*** MEMSET ***
         LR    14,7           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    7,88(13)
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'255'
         ST    6,100(13)
         LA    1,88(,13)
         L     15,=V(FREAD)
         BALR  14,15
         LR    8,15
         LTR   15,15
         BNH   @@L13
         LR    3,7
         IC    2,42(6)
         N     2,=F'192'
         LA    4,64(0,0)
         CLR   2,4
         BNE   @@L11
         LH    8,0(7)
         N     8,=XL4'0000FFFF'
         LA    3,172(,13)
@@L11    EQU   *
         L     12,0(,10)
         LA    2,255(0,0)
         CLR   8,2
         BNH   @@L12
         LR    8,2
@@L12    EQU   *
         L     12,0(,10)
         SLR   4,4
         STC   4,168(8,13)
         MVC   88(4,13),12(11)
         MVC   92(4,13),=A(@@LC7)
         ST    3,96(13)
         L     2,8(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         LTR   3,3
         BNE   @@L6
@@L13    EQU   *
         L     12,0(,10)
         OC    40(2,6),=H'-32768'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         SLR   8,8
@@L3     EQU   *
         L     12,0(,10)
         LR    15,8
* Function __listc epilogue
         PDPEPIL
* Function __listc literal pool
         DS    0F
         LTORG
* Function __listc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
