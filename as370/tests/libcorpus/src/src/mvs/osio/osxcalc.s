         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func osxcalc prologue
OSXCALC  PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function osxcalc code
         SLR   4,4
         SLR   5,5
         LR    6,4
         LR    7,5
         LR    8,4
         LR    9,5
         ST    4,104(13)
         ST    5,4+104(13)
         L     3,4(11)
         MVC   88(4,13),=F'-1'
         L     2,0(11)
         L     15,44(2)
         N     15,=F'16777215'
         ST    15,112(13)
         A     15,=F'32'
         ST    15,120(13)
         L     2,112(13)
         SLR   15,15
         IC    15,16(2)
         ST    15,92(13)
         ST    3,96(13)
         LTR   3,3
         BE    @@L7
         L     4,8(11)
         SLR   5,5
         CLR   3,4
         BH    @@L6
         LTR   3,3
         BL    @@L5
         LA    2,1(0,0)
         CLR   3,2
         BE    @@L4
         SRDL  4,32
         DR    4,3
         B     @@L6
@@L4     EQU   *
         L     12,0(,10)
         LR    5,4
         B     @@L6
@@L5     EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L6     EQU   *
         L     12,0(,10)
         ST    5,96(13)
         LTR   3,3
         BE    @@L7
         L     6,8(11)
         CLR   3,6
         BH    @@L8
         LTR   3,3
         BL    @@L10
         LA    4,1(0,0)
         CLR   3,4
         BE    @@L9
         SRDL  6,32
         DR    6,3
         B     @@L8
@@L9     EQU   *
         L     12,0(,10)
         SLR   6,6
         B     @@L8
@@L10    EQU   *
         L     12,0(,10)
         SR    6,3
         B     @@L8
@@L20    EQU   *
         L     5,120(13)
         LH    4,4(5)
         N     4,=XL4'0000FFFF'
         LH    3,6(5)
         N     3,=XL4'0000FFFF'
         LH    5,8(5)
         N     5,=XL4'0000FFFF'
         A     5,96(13)
         LR    8,5
         SRDA  8,32
         DR    8,2
         AR    3,9
         ST    5,104(13)
         L     8,104(13)
         L     9,4+104(13)
         SRDA  8,32
         ST    8,104(13)
         ST    9,4+104(13)
         DR    8,2
         LR    5,8
         L     9,12(11)
         STC   7,0(9)
         LR    2,4
         SRA   2,8
         STC   2,1(9)
         STC   4,2(9)
         LR    2,3
         SRA   2,8
         STC   2,3(9)
         STC   3,4(9)
         LR    2,5
         SRA   2,8
         STC   2,5(9)
         STC   5,6(9)
         STC   6,7(9)
         ST    6,88(13)
         B     @@L13
@@L7     EQU   *
         L     12,0(,10)
         LR    6,3
@@L8     EQU   *
         L     12,0(,10)
         L     15,0(11)
         IC    3,17(15)
         N     3,=F'15'
         L     2,=A(@V1)
         SLR   4,4
         IC    4,0(3,2)
         LR    2,4
         LTR   4,4
         BE    @@L13
         A     6,=F'1'
         SLR   7,7
@@L21    EQU   *
         C     7,92(13)
         BNL   @@L13
         L     15,120(13)
         LH    5,14(15)
         N     5,=XL4'0000FFFF'
         L     3,96(13)
         CR    3,5
         BL    @@L20
         SR    3,5
         ST    3,96(13)
         A     7,=F'1'
         A     15,=F'16'
         ST    15,120(13)
         B     @@L21
@@L13    EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function osxcalc epilogue
         PDPEPIL
* Function osxcalc literal pool
         DS    0F
         LTORG
* Function osxcalc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
* Program data area
@V1      EQU   *
         DC    X'00'
         DC    X'0A'
         DC    X'00'
         DC    X'00'
         DC    X'00'
         DC    X'00'
         DC    X'08'
         DC    X'08'
         DC    X'14'
         DC    X'13'
         DC    X'0C'
         DC    X'1E'
         DC    X'0C'
         DC    X'13'
         DC    X'0F'
         DC    X'0F'
         END
