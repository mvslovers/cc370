         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBGRT '
         DC    X'0'
@@LC1    EQU   *
         DC    C'CLIBCRT '
         DC    X'0'
         DS    0F
* X-func __ppahrv prologue
@@PPAHRV PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __ppahrv code
         L     7,0(11)
         LTR   7,7
         BE    @@L1
         L     4,16(7)
         LTR   4,4
         BE    @@L3
         L     2,=F'16777215'
         CLR   4,2
         BH    @@L3
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         CLR   4,15
         BE    @@L3
         L     2,=A(@@LC0)
         CLC   0(8,4),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L3
         L     2,16(4)
         LTR   2,2
         BE    @@L4
         A     4,=F'16'
         ST    4,88(13)
         A     4,=F'-16'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         L     2,20(4)
         LTR   2,2
         BE    @@L5
         A     4,=F'20'
         ST    4,88(13)
         A     4,=F'-20'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         L     2,24(4)
         LTR   2,2
         BE    @@L6
         LR    6,4
         A     6,=F'24'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L49    EQU   *
         LTR   5,5
         BE    @@L35
         BCTR  5,0
         L     3,24(4)
         LR    2,5
         SLL   2,2
         L     15,0(2,3)
         SLR   8,8
         ST    8,0(2,3)
         LTR   15,15
         BE    @@L49
         L     2,=F'16777215'
         CLR   15,2
         BH    @@L49
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         B     @@L49
@@L35    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         MVC   36(4,4),=F'0'
         MVC   40(4,4),=F'0'
         MVC   44(4,4),=F'0'
         L     2,32(4)
         LTR   2,2
         BE    @@L11
         LR    6,4
         A     6,=F'32'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L50    EQU   *
         LTR   5,5
         BE    @@L37
         BCTR  5,0
         L     3,32(4)
         LR    2,5
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L50
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L50
@@L37    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         L     2,68(4)
         LTR   2,2
         BE    @@L16
         LR    6,4
         A     6,=F'68'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L51    EQU   *
         LTR   5,5
         BE    @@L39
         BCTR  5,0
         L     3,68(4)
         LR    2,5
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L51
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L51
@@L39    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L16    EQU   *
         L     12,0(,10)
         L     2,72(4)
         LTR   2,2
         BE    @@L21
         LR    6,4
         A     6,=F'72'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L52    EQU   *
         LTR   5,5
         BE    @@L41
         BCTR  5,0
         L     3,72(4)
         LR    2,5
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L52
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L52
@@L41    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L21    EQU   *
         L     12,0(,10)
         L     2,76(4)
         LTR   2,2
         BE    @@L26
         A     4,=F'76'
         ST    4,88(13)
         A     4,=F'-76'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L26    EQU   *
         L     12,0(,10)
         SLR   3,3
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         MVC   16(4,7),=F'0'
         L     2,12(7)
         LTR   2,2
         BE    @@L1
         L     3,=F'16777215'
         CLR   2,3
         BH    @@L1
         LR    6,7
         A     6,=F'12'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
@@L53    EQU   *
         LTR   5,5
         BE    @@L43
         BCTR  5,0
         L     3,12(7)
         LR    2,5
         SLL   2,2
         L     4,0(2,3)
         LTR   4,4
         BE    @@L53
         L     8,=F'16777215'
         CLR   4,8
         BH    @@L53
         L     2,=A(@@LC1)
         CLC   0(8,4),0(2)
         LA    3,1(0,0)
         BH    *+12
         BL    *+6
         SLR   3,3
         LNR   3,3
         LTR   3,3
         BNE   @@L53
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         B     @@L53
@@L43    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function __ppahrv epilogue
         PDPEPIL
* Function __ppahrv literal pool
         DS    0F
         LTORG
* Function __ppahrv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
