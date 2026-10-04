         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0123456789abcdefghijklmnopqrstuvwxyz'
         DC    X'0'
         DS    0F
* X-func strtoul prologue
STRTOUL  PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtoul code
         SLR   4,4
         SLR   5,5
         LR    8,4
         LR    9,5
         ST    4,104(13)
         ST    5,4+104(13)
         L     15,8(11)
         L     6,0(11)
         MVC   88(4,13),=F'0'
         MVC   92(4,13),88(13)
         MVC   96(4,13),88(13)
         MVC   100(4,13),88(13)
         LTR   15,15
         BL    @@L3
         LA    2,1(0,0)
         CR    15,2
         BE    @@L3
         LA    3,36(0,0)
         CR    15,3
         BNH   @@L2
@@L3     EQU   *
         L     12,0(,10)
         L     7,4(11)
         LTR   7,7
         BE    @@L4
         MVC   0(4,7),0(11)
@@L4     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         SLR   15,15
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         L     3,0(11)
         SLR   2,2
         IC    2,0(3)
         L     3,=V(@@ISBUF)
         L     3,0(3)
@@L56    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L49
         A     6,=F'1'
         SLR   2,2
         IC    2,0(6)
         B     @@L56
@@L49    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'60'
         BNE   @@L8
         MVC   92(4,13),=F'1'
         B     @@L57
@@L8     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L9
@@L57    EQU   *
         L     12,0(,10)
         A     6,=F'1'
@@L9     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L12
         LA    7,16(0,0)
         CLR   15,7
         BNE   @@L11
@@L12    EQU   *
         L     12,0(,10)
         CLI   0(6),240
         BNE   @@L11
         IC    2,1(6)
         CLM   2,1,=XL1'A7'
         BE    @@L13
         CLM   2,1,=XL1'E7'
         BNE   @@L11
@@L13    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,2(6)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    3,0(2,3)
         ST    3,112(13)
         SLR   3,3
@@L19    EQU   *
         L     2,=A(@V1)
         SLR   7,7
         IC    7,0(3,2)
         C     7,112(13)
         BE    @@L54
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L19
         B     @@L11
@@L54    EQU   *
         L     12,0(,10)
         LA    7,15(0,0)
         CR    3,7
         BH    @@L11
         A     6,=F'2'
         LA    15,16(0,0)
         B     @@L20
@@L11    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L20
         LA    15,8(0,0)
         CLI   0(6),240
         BE    @@L20
         LA    15,10(0,0)
@@L20    EQU   *
         L     12,0(,10)
         L     4,=F'-1'
         SLR   5,5
         CLR   15,4
         BH    @@L26
         LTR   15,15
         BL    @@L25
         LA    2,1(0,0)
         CLR   15,2
         BE    @@L24
         SRDL  4,32
         DR    4,15
         B     @@L26
@@L24    EQU   *
         L     12,0(,10)
         LR    5,4
         B     @@L26
@@L25    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L26    EQU   *
         L     12,0(,10)
         L     8,=F'-1'
         CLR   15,8
         BH    @@L29
         LTR   15,15
         BL    @@L28
         LA    3,1(0,0)
         CLR   15,3
         BE    @@L27
         SRDL  8,32
         DR    8,15
         B     @@L29
@@L27    EQU   *
         L     12,0(,10)
         SLR   8,8
         B     @@L29
@@L28    EQU   *
         L     12,0(,10)
         SR    8,15
@@L29    EQU   *
         L     12,0(,10)
         LR    7,8
@@L30    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    4,0(2,3)
         SLR   3,3
@@L38    EQU   *
         L     2,=A(@V1)
         SLR   8,8
         IC    8,0(3,2)
         CR    8,4
         BE    @@L55
         A     3,=F'1'
         LA    9,35(0,0)
         CR    3,9
         BNH   @@L38
         LA    2,36(0,0)
@@L37    EQU   *
         CR    2,15
         BNL   @@L31
         MVC   96(4,13),=F'1'
         L     3,100(13)
         LTR   3,3
         BNE   @@L32
         L     8,88(13)
         CLR   8,5
         BH    @@L42
         BNE   @@L41
         CR    2,7
         BNH   @@L41
@@L42    EQU   *
         L     12,0(,10)
         MVC   100(4,13),96(13)
         B     @@L32
@@L55    EQU   *
         L     12,0(,10)
         LR    2,3
         B     @@L37
@@L41    EQU   *
         L     12,0(,10)
         L     9,88(13)
         ST    9,108(13)
         L     8,104(13)
         L     9,4+104(13)
         MR    8,15
         ST    8,104(13)
         ST    9,4+104(13)
         AR    9,2
         ST    9,88(13)
@@L32    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L30
@@L31    EQU   *
         L     12,0(,10)
         L     9,4(11)
         LTR   9,9
         BE    @@L43
         LR    2,6
         L     3,96(13)
         LTR   3,3
         BNE   @@L45
         L     2,0(11)
@@L45    EQU   *
         L     12,0(,10)
         L     7,4(11)
         ST    2,0(7)
@@L43    EQU   *
         L     12,0(,10)
         L     8,100(13)
         LTR   8,8
         BE    @@L46
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         L     15,=F'-1'
         B     @@L1
@@L46    EQU   *
         L     12,0(,10)
         L     15,88(13)
         L     9,92(13)
         LTR   9,9
         BE    @@L1
         LCR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function strtoul epilogue
         PDPEPIL
* Function strtoul literal pool
         DS    0F
         LTORG
* Function strtoul page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
