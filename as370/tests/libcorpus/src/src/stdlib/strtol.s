         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0123456789abcdefghijklmnopqrstuvwxyz'
         DC    X'0'
         DS    0F
* X-func strtol prologue
STRTOL   PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtol code
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
@@L62    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L55
         A     6,=F'1'
         SLR   2,2
         IC    2,0(6)
         B     @@L62
@@L55    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'60'
         BNE   @@L8
         MVC   92(4,13),=F'1'
         B     @@L63
@@L8     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L9
@@L63    EQU   *
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
         ST    3,116(13)
         SLR   3,3
@@L19    EQU   *
         L     2,=A(@V1)
         SLR   7,7
         IC    7,0(3,2)
         C     7,116(13)
         BE    @@L60
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L19
         B     @@L11
@@L60    EQU   *
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
         L     7,92(13)
         X     7,=F'1'
         L     2,=F'-2147483648'
         SR    2,7
         LR    7,2
         LR    4,2
         SLR   5,5
         CLR   15,2
         BH    @@L28
         LTR   15,15
         BL    @@L27
         LA    3,1(0,0)
         CLR   15,3
         BE    @@L26
         SRDL  4,32
         DR    4,15
         B     @@L28
@@L26    EQU   *
         L     12,0(,10)
         LR    5,2
         B     @@L28
@@L27    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L28    EQU   *
         L     12,0(,10)
         LR    8,7
         CLR   15,7
         BH    @@L31
         LTR   15,15
         BL    @@L30
         LA    2,1(0,0)
         CLR   15,2
         BE    @@L29
         SRDL  8,32
         DR    8,15
         B     @@L31
@@L29    EQU   *
         L     12,0(,10)
         SLR   8,8
         B     @@L31
@@L30    EQU   *
         L     12,0(,10)
         SR    8,15
@@L31    EQU   *
         L     12,0(,10)
         ST    8,112(13)
@@L32    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    4,0(2,3)
         SLR   3,3
@@L40    EQU   *
         L     2,=A(@V1)
         SLR   8,8
         IC    8,0(3,2)
         CR    8,4
         BE    @@L61
         A     3,=F'1'
         LA    9,35(0,0)
         CR    3,9
         BNH   @@L40
         LA    2,36(0,0)
@@L39    EQU   *
         CR    2,15
         BNL   @@L33
         MVC   96(4,13),=F'1'
         L     3,100(13)
         LTR   3,3
         BNE   @@L34
         L     8,88(13)
         CLR   8,5
         BH    @@L44
         BNE   @@L43
         C     2,112(13)
         BNH   @@L43
@@L44    EQU   *
         L     12,0(,10)
         MVC   100(4,13),96(13)
         B     @@L34
@@L61    EQU   *
         L     12,0(,10)
         LR    2,3
         B     @@L39
@@L43    EQU   *
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
@@L34    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L32
@@L33    EQU   *
         L     12,0(,10)
         L     9,4(11)
         LTR   9,9
         BE    @@L45
         LR    2,6
         L     3,96(13)
         LTR   3,3
         BNE   @@L47
         L     2,0(11)
@@L47    EQU   *
         L     12,0(,10)
         L     8,4(11)
         ST    2,0(8)
@@L45    EQU   *
         L     12,0(,10)
         L     9,100(13)
         LTR   9,9
         BE    @@L48
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         XC    92(4,13),=F'1'
         L     15,=F'-2147483648'
         S     15,92(13)
         B     @@L1
@@L48    EQU   *
         L     12,0(,10)
         L     15,88(13)
         L     2,92(13)
         LTR   2,2
         BE    @@L1
         LCR   15,15
         L     3,88(13)
         CLR   3,7
         BNE   @@L1
         L     15,=F'-2147483648'
@@L1     EQU   *
         L     12,0(,10)
* Function strtol epilogue
         PDPEPIL
* Function strtol literal pool
         DS    0F
         LTORG
* Function strtol page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
