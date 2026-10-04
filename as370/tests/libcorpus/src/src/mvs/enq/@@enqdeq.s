         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __enqdeq prologue
@@ENQDEQ PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __enqdeq code
         L     6,0(11)
         L     7,4(11)
         L     8,8(11)
         LA    4,96(,13)
         LA    5,12(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         LA    2,1(0,0)
         LTR   6,6
         BE    @@L4
         LTR   7,7
         BE    @@L4
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         MVI   96(13),192
         STC   15,97(13)
         SLR   15,15
         IC    2,0(6)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L12
         LR    3,6
@@L9     EQU   *
         IC    2,0(3)
         STC   2,112(15,13)
         A     15,=F'1'
         A     3,=F'1'
         LA    2,7(0,0)
         CR    15,2
         BH    @@L7
         IC    2,0(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L9
@@L7     EQU   *
         L     12,0(,10)
         LA    3,7(0,0)
         CR    15,3
         BH    @@L28
@@L12    EQU   *
         L     12,0(,10)
         LA    2,64(0,0)
         STC   2,112(15,13)
         A     15,=F'1'
         B     @@L7
@@L28    EQU   *
         L     12,0(,10)
         LA    2,112(,13)
         ST    2,100(13)
         ST    7,104(13)
         LR    2,8
         N     2,=F'3'
         LA    3,1(0,0)
         CLR   2,3
         BE    @@L15
         LA    3,2(0,0)
         CLR   2,3
         BNE   @@L13
         OI    98(13),72
         B     @@L13
@@L15    EQU   *
         L     12,0(,10)
         OI    98(13),64
@@L13    EQU   *
         L     12,0(,10)
         L     2,12(11)
         LTR   2,2
         BE    @@L17
         OI    98(13),1
         DS    0H       Request DEQ
         LA    1,96(13)
         SVC   48       DEQ
         B     @@L18
@@L17    EQU   *
         L     12,0(,10)
         LR    2,8
         N     2,=F'4'
         LTR   2,2
         BE    @@L19
         OI    98(13),128
@@L19    EQU   *
         L     12,0(,10)
         LR    2,8
         N     2,=F'240'
         LA    3,64(0,0)
         CLR   2,3
         BE    @@L22
         BH    @@L25
         LA    3,32(0,0)
         CLR   2,3
         BE    @@L23
         B     @@L24
@@L25    EQU   *
         L     12,0(,10)
         LA    3,128(0,0)
         CLR   2,3
         BNE   @@L24
         OI    98(13),7
         B     @@L20
@@L22    EQU   *
         L     12,0(,10)
         OI    98(13),3
         B     @@L20
@@L23    EQU   *
         L     12,0(,10)
         OI    98(13),2
         B     @@L20
@@L24    EQU   *
         L     12,0(,10)
         OI    98(13),1
@@L20    EQU   *
         DS    0H       Request ENQ
         LA    1,96(13)
         SVC   56       ENQ
@@L18    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,99(13)
@@L4     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __enqdeq epilogue
         PDPEPIL
* Function __enqdeq literal pool
         DS    0F
         LTORG
* Function __enqdeq page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
