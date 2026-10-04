         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __jesprb prologue
@@JESPRB PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __jesprb code
         L     2,0(11)
         L     9,4(11)
         L     6,8(11)
         MVC   20(4,6),=F'0'
         AR    9,2
         LR    7,2
         A     7,=F'10'
@@L27    EQU   *
         LR    8,7
         A     8,=F'3'
         CLR   8,9
         BH    @@L3
         IC    4,0(7)
         CLM   4,1,=XL1'FF'
         BE    @@L3
         IC    5,1(7)
         LR    3,5
         N     3,=XL4'000000FF'
         LR    2,3
         N     2,=F'16'
         LTR   2,2
         BE    @@L6
         LR    2,7
         A     2,=F'4'
         CLR   2,9
         BH    @@L32
         LR    8,2
         N     3,=F'8'
         LTR   3,3
         BE    @@L8
         LR    4,7
         A     4,=F'6'
         CLR   4,9
         BH    @@L32
         LH    2,0(2)
         N     2,=XL4'0000FFFF'
         LR    8,4
         CL    2,4(6)
         BNH   @@L10
         L     3,0(6)
         LTR   3,3
         BE    @@L11
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         ST    2,4(6)
         MVC   88(4,13),=F'1'
         A     2,=F'4'
         ST    2,92(13)
         A     2,=F'-4'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,0(6)
         LTR   15,15
         BNE   @@L10
         ST    15,12(6)
         ST    15,28(6)
         MVC   20(4,6),=F'3'
         B     @@L31
@@L10    EQU   *
         L     12,0(,10)
         ST    2,8(6)
         MVC   12(4,6),=F'0'
         MVC   28(4,6),=F'1'
         IC    2,1(7)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L8
         LR    8,4
         A     8,=F'1'
@@L8     EQU   *
         L     12,0(,10)
         MVC   104(4,13),0(6)
         L     2,104(13)
         LTR   2,2
         BE    @@L33
         L     2,28(6)
         LTR   2,2
         BE    @@L33
         LH    15,2(7)
         N     15,=XL4'0000FFFF'
         LR    2,8
         AR    2,15
         CLR   2,9
         BH    @@L32
         L     3,12(6)
         LR    2,3
         AR    2,15
         CL    2,8(6)
         BNH   @@L17
@@L33    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'2'
         B     @@L30
@@L17    EQU   *
         L     12,0(,10)
         L     4,104(13)
         AR    4,3
         LR    5,15
         LR    2,8
         LR    3,15
         MVCL  4,2
         LH    3,2(7)
         N     3,=XL4'0000FFFF'
         A     3,12(6)
         ST    3,12(6)
         IC    2,1(7)
         N     2,=F'2'
         LTR   2,2
         BE    @@L18
         LTR   3,3
         BE    @@L19
         L     2,16(6)
         A     2,=F'1'
         ST    2,16(6)
@@L19    EQU   *
         L     12,0(,10)
         MVC   88(4,13),0(6)
         MVC   92(4,13),12(6)
         MVC   96(4,13),16(11)
         L     2,12(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         LTR   15,15
         BL    @@L29
         MVC   12(4,6),=F'0'
         MVC   28(4,6),=F'0'
@@L18    EQU   *
         L     12,0(,10)
         LH    7,2(7)
         N     7,=XL4'0000FFFF'
         B     @@L28
@@L6     EQU   *
         L     12,0(,10)
         SLL   5,24
         SRA   5,24
         C     5,=F'0'
         BNL   @@L21
         LR    8,7
         A     8,=F'4'
@@L21    EQU   *
         L     12,0(,10)
         LR    2,4
         N     2,=XL4'000000FF'
         AR    2,8
         CLR   2,9
         BNH   @@L22
@@L32    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'4'
@@L30    EQU   *
         L     12,0(,10)
         MVC   96(4,13),12(11)
         MVC   100(4,13),16(11)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         B     @@L1
@@L22    EQU   *
         L     12,0(,10)
         CLM   4,1,=XL1'00'
         BE    @@L23
         L     2,16(6)
         A     2,=F'1'
         ST    2,16(6)
@@L23    EQU   *
         L     12,0(,10)
         ST    8,88(13)
         SLR   2,2
         IC    2,0(7)
         ST    2,92(13)
         MVC   96(4,13),16(11)
         L     2,12(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
         LTR   15,15
         BNL   @@L24
@@L29    EQU   *
         L     12,0(,10)
         MVC   20(4,6),=F'1'
         ST    15,24(6)
@@L31    EQU   *
         L     12,0(,10)
         L     15,=F'-1'
         B     @@L1
@@L24    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(7)
         LR    7,2
@@L28    EQU   *
         L     12,0(,10)
         AR    7,8
         B     @@L27
@@L3     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function __jesprb epilogue
         PDPEPIL
* Function __jesprb literal pool
         DS    0F
         LTORG
* Function __jesprb page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* Function giveup,F2 prologue
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
* Function giveup code
         L     3,0(11)
         SLR   15,15
         L     2,28(3)
         LTR   2,2
         BE    @@L35
         L     4,12(3)
         LTR   4,4
         BE    @@L35
         L     2,16(3)
         A     2,=F'1'
         ST    2,16(3)
         MVC   88(4,13),0(3)
         ST    4,92(13)
         MVC   96(4,13),12(11)
         L     2,8(11)
         LA    1,88(,13)
         LA    15,0(2)
         BALR  14,15
@@L35    EQU   *
         L     12,0(,10)
         MVC   12(4,3),=F'0'
         MVC   28(4,3),=F'0'
         LTR   15,15
         BNL   @@L36
         MVC   20(4,3),=F'1'
         ST    15,24(3)
         L     15,=F'-1'
         B     @@L34
@@L36    EQU   *
         L     12,0(,10)
         MVC   20(4,3),4(11)
         SLR   15,15
@@L34    EQU   *
         L     12,0(,10)
* Function giveup epilogue
         PDPEPIL
* Function giveup literal pool
         DS    0F
         LTORG
* Function giveup page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
