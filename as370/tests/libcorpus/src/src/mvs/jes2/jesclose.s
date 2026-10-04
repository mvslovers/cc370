         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesclose prologue
JESCLOSE PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesclose code
         L     8,0(11)
         LTR   8,8
         BE    @@L3
         L     3,0(8)
         LTR   3,3
         BE    @@L3
         L     2,16(3)
         LTR   2,2
         BE    @@L5
         A     3,=F'16'
         ST    3,88(13)
         A     3,=F'-16'
         LA    1,88(,13)
         L     15,=V(JESJOBFR)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         L     2,20(3)
         LTR   2,2
         BE    @@L6
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   20(4,3),=F'0'
@@L6     EQU   *
         L     12,0(,10)
         L     2,24(3)
         LTR   2,2
         BE    @@L7
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   24(4,3),=F'0'
@@L7     EQU   *
         L     12,0(,10)
         L     2,28(3)
         LTR   2,2
         BE    @@L8
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   28(4,3),=F'0'
@@L8     EQU   *
         L     12,0(,10)
         L     2,12(3)
         LTR   2,2
         BE    @@L9
         LR    7,3
         A     7,=F'12'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    6,15
         SLR   4,4
@@L18    EQU   *
         CLR   4,6
         BNL   @@L17
         L     2,12(3)
         LR    5,4
         SLL   5,2
         L     2,0(5,2)
         LTR   2,2
         BE    @@L12
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@JSCLOS)
         BALR  14,15
         L     2,12(3)
         SLR   9,9
         ST    9,0(5,2)
@@L12    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         B     @@L18
@@L17    EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         L     2,8(3)
         LTR   2,2
         BE    @@L15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@CPCLOS)
         BALR  14,15
         MVC   8(4,3),=F'0'
@@L15    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         MVC   0(4,8),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
* Function jesclose epilogue
         PDPEPIL
* Function jesclose literal pool
         DS    0F
         LTORG
* Function jesclose page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
