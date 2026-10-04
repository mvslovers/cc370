         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* Function digit,F1 prologue
@@F1     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function digit code
         L     3,4(11)
         IC    15,3(11)
         LA    2,16(,15)
         CLM   2,1,=XL1'09'
         BH    @@L2
         LR    2,15
         N     2,=XL4'000000FF'
         A     2,=F'-240'
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LA    2,16(0,0)
         CLR   3,2
         BNE   @@L11
         CLM   15,1,=XL1'80'
         BNH   @@L10
         CLM   15,1,=XL1'86'
         BH    @@L10
         LR    2,15
         N     2,=XL4'000000FF'
         A     2,=F'-119'
         B     @@L3
@@L10    EQU   *
         L     12,0(,10)
         CLM   15,1,=XL1'C0'
         BNH   @@L11
         CLM   15,1,=XL1'C6'
         BH    @@L11
         LR    2,15
         N     2,=XL4'000000FF'
         A     2,=F'-183'
@@L3     EQU   *
         L     12,0(,10)
         LR    15,2
         CR    2,3
         BL    @@L1
@@L11    EQU   *
         L     12,0(,10)
         L     15,=F'-1'
@@L1     EQU   *
         L     12,0(,10)
* Function digit epilogue
         PDPEPIL
* Function digit literal pool
         DS    0F
         LTORG
* Function digit page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function number,F2 prologue
@@F2     PDPPRLG CINDEX=1,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function number code
         SLR   4,4
         SLR   5,5
         ST    4,96(13)
         ST    5,4+96(13)
         L     3,0(11)
         SLR   8,8
         LA    7,10(0,0)
         LR    9,8
         IC    6,0(3)
         LA    2,16(,6)
         LR    15,8
         CLM   2,1,=XL1'09'
         BH    @@L12
         CLM   6,1,=XL1'F0'
         BNE   @@L17
         LA    7,8(0,0)
         A     3,=F'1'
         LA    9,1(0,0)
         IC    2,0(3)
         CLM   2,1,=XL1'A7'
         BE    @@L16
         CLM   2,1,=XL1'E7'
         BNE   @@L17
@@L16    EQU   *
         L     12,0(,10)
         LA    7,16(0,0)
         A     3,=F'1'
         LR    9,8
         B     @@L17
@@L23    EQU   *
         LR    4,15
         X     4,=F'-1'
         SLR   5,5
         CLR   7,4
         BH    @@L22
         LA    2,1(0,0)
         CLR   7,2
         BE    @@L20
         SRDL  4,32
         DR    4,7
         B     @@L22
@@L20    EQU   *
         L     12,0(,10)
         LR    5,4
@@L22    EQU   *
         L     12,0(,10)
         CLR   8,5
         BH    @@L25
         ST    8,100(13)
         L     8,96(13)
         L     9,4+96(13)
         MR    8,7
         ST    8,96(13)
         ST    9,4+96(13)
         L     8,100(13)
         AR    8,15
         A     3,=F'1'
         LA    9,1(0,0)
@@L17    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(3)
         ST    2,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         LTR   15,15
         BNL   @@L23
         LR    15,9
         LTR   9,9
         BE    @@L12
         B     @@L24
@@L25    EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L12
@@L24    EQU   *
         L     12,0(,10)
         L     2,4(11)
         ST    8,0(2)
         LR    15,3
@@L12    EQU   *
         L     12,0(,10)
* Function number epilogue
         PDPEPIL
* Function number literal pool
         DS    0F
         LTORG
* Function number page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         DS    0F
@V1      EQU   *
         DC    F'-1'
         DC    F'16777215'
         DC    F'65535'
         DC    F'255'
         DS    0F
* X-func *@@INATON prologue
@@INATON PDPPRLG CINDEX=2,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function *@@INATON code
         L     15,0(11)
         L     7,4(11)
         LR    5,15
         LTR   15,15
         BE    @@L26
         SLR   6,6
@@L28    EQU   *
         ST    15,88(13)
         LR    4,6
         SLL   4,2
         LA    2,96(,13)
         AR    2,4
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L50
         IC    2,0(15)
         CLM   2,1,=XL1'4B'
         BNE   @@L29
         LA    2,3(0,0)
         CLR   6,2
         BE    @@L52
         A     15,=F'1'
         A     6,=F'1'
         B     @@L28
@@L29    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'00'
         BE    @@L34
         CLM   2,1,=XL1'40'
         BE    @@L34
         CLM   2,1,=XL1'05'
         BE    @@L34
         SLR   5,5
         CLM   2,1,=XL1'15'
         BNE   @@L26
@@L34    EQU   *
         L     12,0(,10)
         SLR   15,15
         CR    15,6
         BNL   @@L47
         LA    3,96(,13)
@@L39    EQU   *
         L     2,0(3)
         LA    5,255(0,0)
         CLR   2,5
         BH    @@L52
         A     15,=F'1'
         A     3,=F'4'
         CR    15,6
         BL    @@L39
@@L47    EQU   *
         L     12,0(,10)
         L     3,96(13,4)
         SLR   5,5
         L     2,=A(@V1)
         CL    3,0(4,2)
         BH    @@L26
         B     @@L40
@@L50    EQU   *
         L     12,0(,10)
         LR    5,15
         B     @@L26
@@L52    EQU   *
         L     12,0(,10)
         SLR   5,5
         B     @@L26
@@L40    EQU   *
         L     12,0(,10)
         SLR   15,15
         CR    15,6
         BNL   @@L49
         LA    5,96(,13)
         LA    4,24(0,0)
@@L44    EQU   *
         L     2,0(5)
         SLL   2,0(4)
         OR    3,2
         A     15,=F'1'
         A     4,=F'-8'
         A     5,=F'4'
         CR    15,6
         BL    @@L44
@@L49    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L45
         ST    3,0(7)
@@L45    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L26    EQU   *
         L     12,0(,10)
         LR    15,5
* Function *@@INATON epilogue
         PDPEPIL
* Function *@@INATON literal pool
         DS    0F
         LTORG
* Function *@@INATON page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         END
