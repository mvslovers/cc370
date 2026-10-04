         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_manager_term'
* Program text area
@@LC0    EQU   *
         DC    C'cthread_manager_term(%08X): dispatch thread did '
         DC    C'not stop, storage retained to avoid use-after-fr'
         DC    C'ee'
         DC    X'0'
@@LC1    EQU   *
         DC    C'cthread_manager_term(%08X): %u worker(s) still r'
         DC    C'unning, manager storage retained to avoid use-af'
         DC    C'ter-free'
         DC    X'0'
         DS    0F
* X-func *@@CMTERM prologue
@@CMTERM PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CMTERM code
         SLR   8,8
         LR    9,8
         L     2,0(11)
         LTR   2,2
         BE    @@L3
         L     4,0(2)
         LTR   4,4
         BE    @@L3
         ST    4,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         L     2,36(4)
         LA    5,1(0,0)
         CR    2,5
         BH    @@L5
         MVC   36(4,4),=F'2'
@@L5     EQU   *
         L     12,0(,10)
         LR    7,4
         A     7,=F'12'
         ST    7,88(13)
         MVC   92(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         LTR   3,3
         BNE   @@L6
         ST    4,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L6     EQU   *
         L     12,0(,10)
         L     2,8(4)
         ST    2,104(13)
         LTR   2,2
         BE    @@L21
         L     2,44(4)
         LTR   2,2
         BNE   @@L9
         LA    2,1(0,0)
@@L9     EQU   *
         L     12,0(,10)
         LR    3,2
         SLL   3,3
         AR    3,2
         AR    3,2
         A     3,=F'20'
         LR    5,2
         SLL   5,4
         SR    5,2
         SLL   5,2
         A     5,=F'50'
         LR    6,8
         CLR   8,3
         BNL   @@L41
@@L15    EQU   *
         L     2,104(13)
         L     2,16(2)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L21
         STIMER WAIT,BINTVL==F'10'   0.10 seconds
         L     2,36(4)
         LA    15,1(0,0)
         CR    2,15
         BH    @@L14
         MVC   36(4,4),=F'2'
@@L14    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         MVC   92(4,13),=F'2'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         A     6,=F'1'
         CLR   6,3
         BL    @@L15
@@L41    EQU   *
         L     12,0(,10)
         LR    3,4
         A     3,=F'12'
         ST    3,88(13)
         MVC   92(4,13),=F'3'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         SLR   6,6
@@L50    EQU   *
         CLR   6,5
         BNL   @@L49
         L     2,104(13)
         L     2,16(2)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L21
         STIMER WAIT,BINTVL==F'10'   0.10 seconds
         ST    3,88(13)
         MVC   92(4,13),=F'3'
         LA    1,88(,13)
         L     15,=V(@@CTPOST)
         BALR  14,15
         A     6,=F'1'
         B     @@L50
@@L8     EQU   *
@@L49    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC0)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L53
@@L21    EQU   *
         L     12,0(,10)
         L     2,28(4)
         LTR   2,2
         BE    @@L32
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    3,15
         LR    7,4
         A     7,=F'28'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         LA    6,1(0,0)
@@L51    EQU   *
         CLR   6,5
         BH    @@L44
         ST    7,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         LTR   15,15
         BE    @@L25
         L     15,16(15)
         LTR   15,15
         BE    @@L25
         L     2,8(15)
         LTR   2,2
         BE    @@L25
         L     2,16(15)
         N     2,=F'1073741824'
         LTR   2,2
         BNE   @@L25
         A     9,=F'1'
@@L25    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L51
@@L44    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNE   @@L22
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L22    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L32
         MVC   88(4,13),=A(@@LC1)
         ST    4,92(13)
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L53    EQU   *
         L     12,0(,10)
         L     8,=F'-1'
         B     @@L3
@@L32    EQU   *
         L     12,0(,10)
         L     2,104(13)
         LTR   2,2
         BE    @@L33
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CTDEL)
         BALR  14,15
         MVC   8(4,4),=F'0'
@@L33    EQU   *
         L     12,0(,10)
         L     2,32(4)
         LTR   2,2
         BE    @@L34
         LR    3,4
         A     3,=F'32'
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
@@L52    EQU   *
         LTR   6,6
         BE    @@L46
         ST    3,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         ST    15,108(13)
         LTR   15,15
         BE    @@L37
         LA    2,108(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CMQDEL)
         BALR  14,15
@@L37    EQU   *
         L     12,0(,10)
         BCTR  6,0
         B     @@L52
@@L46    EQU   *
         L     12,0(,10)
         A     4,=F'32'
         ST    4,88(13)
         A     4,=F'-32'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L34    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,0(11)
         MVC   0(4,2),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@CMTERM epilogue
         PDPEPIL
* Function *@@CMTERM literal pool
         DS    0F
         LTORG
* Function *@@CMTERM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
