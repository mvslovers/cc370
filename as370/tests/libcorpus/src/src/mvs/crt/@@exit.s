         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __exit prologue
@@EXIT   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __exit code
         L     7,0(11)
         LA    1,88(,13)
         L     15,=V(@@GRTGET)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L3
         L     2,16(15)
         LTR   2,2
         BE    @@L4
         LR    6,15
         A     6,=F'16'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L43    EQU   *
         LTR   4,4
         BE    @@L34
         BCTR  4,0
         L     2,16(5)
         LR    3,4
         SLL   3,2
         L     15,0(3,2)
         LTR   15,15
         BE    @@L7
         ST    7,88(13)
         L     2,20(5)
         L     2,0(3,2)
         ST    2,92(13)
         LA    1,88(,13)
         LA    15,0(15)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         L     2,16(5)
         SLR   8,8
         ST    8,0(3,2)
         L     2,20(5)
         ST    8,0(3,2)
         B     @@L43
@@L34    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
         A     5,=F'20'
         ST    5,88(13)
         A     5,=F'-20'
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         L     2,24(5)
         LTR   2,2
         BE    @@L9
         LR    6,5
         A     6,=F'24'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L49    EQU   *
         LTR   4,4
         BE    @@L36
         BCTR  4,0
         L     3,24(5)
         LR    2,4
         SLL   2,2
         L     2,0(2,3)
         LTR   2,2
         BE    @@L49
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         CL    2,0(15)
         BNE   @@L13
         LA    1,88(,13)
         L     15,=V(@@GTIN)
         BALR  14,15
         B     @@L48
@@L13    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         CL    2,0(15)
         BNE   @@L14
         LA    1,88(,13)
         L     15,=V(@@GTOUT)
         BALR  14,15
         B     @@L48
@@L14    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         CL    2,0(15)
         BNE   @@L49
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
@@L48    EQU   *
         L     12,0(,10)
         MVC   0(4,15),=F'0'
         B     @@L49
@@L36    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L9     EQU   *
         L     12,0(,10)
         L     2,32(5)
         LTR   2,2
         BE    @@L17
         LR    6,5
         A     6,=F'32'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L50    EQU   *
         LTR   4,4
         BE    @@L38
         BCTR  4,0
         L     2,32(5)
         LR    3,4
         SLL   3,2
         L     2,0(3,2)
         LTR   2,2
         BE    @@L50
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,32(5)
         SLR   8,8
         ST    8,0(3,2)
         B     @@L50
@@L38    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L17    EQU   *
         L     12,0(,10)
         L     2,68(5)
         LTR   2,2
         BE    @@L22
         LR    6,5
         A     6,=F'68'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L51    EQU   *
         LTR   4,4
         BE    @@L40
         BCTR  4,0
         L     2,68(5)
         LR    3,4
         SLL   3,2
         L     2,0(3,2)
         LTR   2,2
         BE    @@L51
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,68(5)
         SLR   8,8
         ST    8,0(3,2)
         B     @@L51
@@L40    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L22    EQU   *
         L     12,0(,10)
         L     2,72(5)
         LTR   2,2
         BE    @@L27
         LR    6,5
         A     6,=F'72'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    4,15
@@L52    EQU   *
         LTR   4,4
         BE    @@L42
         BCTR  4,0
         L     2,72(5)
         LR    3,4
         SLL   3,2
         L     2,0(3,2)
         LTR   2,2
         BE    @@L52
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         L     2,72(5)
         SLR   8,8
         ST    8,0(3,2)
         B     @@L52
@@L42    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L27    EQU   *
         L     12,0(,10)
         L     2,76(5)
         LTR   2,2
         BE    @@L3
         A     5,=F'76'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARFRE)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(@@EXITA)
         BALR  14,15
* Function __exit epilogue
         PDPEPIL
* Function __exit literal pool
         DS    0F
         LTORG
* Function __exit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
