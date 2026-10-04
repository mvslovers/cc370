         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'1101004800'
         DC    F'0'
         DC    F'1113849856'
         DC    F'0'
         DC    F'1143410688'
         DC    F'0'
         DC    F'1197432336'
         DC    F'0'
         DC    F'1310951154'
         DC    F'1874919424'
         DC    F'1531896534'
         DC    F'3558193243'
         DC    F'1981304579'
         DC    F'3913284085'
         DS    0F
* Function tenpow,F1 prologue
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
* Function tenpow code
         L     15,0(11)
         LD    0,=D'1.0E+0'
         SLR   4,4
         LTR   15,15
         BE    @@L8
@@L6     EQU   *
         LR    2,15
         N     2,=F'1'
         LTR   2,2
         BE    @@L4
         LR    3,4
         SLL   3,3
         L     2,=A(@V1)
         MD    0,0(3,2)
@@L4     EQU   *
         L     12,0(,10)
         A     4,=F'1'
         SRA   15,1
         BNE   @@L6
@@L8     EQU   *
         L     12,0(,10)
* Function tenpow epilogue
         PDPEPIL
* Function tenpow literal pool
         DS    0F
         LTORG
* Function tenpow page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func strtod prologue
STRTOD   PDPPRLG CINDEX=1,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function strtod code
         L     15,0(11)
         LD    4,=D'0.0'
         SLR   9,9
         ST    9,96(13)
         LR    7,9
         LR    8,9
         LR    6,9
         ST    9,100(13)
         SLR   2,2
         IC    2,0(15)
         L     5,=V(@@ISBUF)
         L     3,0(5)
@@L74    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L66
         A     15,=F'1'
         SLR   2,2
         IC    2,0(15)
         B     @@L74
@@L66    EQU   *
         L     12,0(,10)
         IC    2,0(15)
         CLM   2,1,=XL1'60'
         BNE   @@L13
         LA    9,1(0,0)
         AR    15,9
         B     @@L14
@@L13    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L14
@@L77    EQU   *
         A     15,=F'1'
@@L14    EQU   *
         L     12,0(,10)
         IC    4,0(15)
         LR    2,4
         N     2,=XL4'000000FF'
         L     3,0(5)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BE    @@L68
         MVC   96(4,13),=F'1'
         LTR   7,7
         BNE   @@L19
         CLM   4,1,=XL1'F0'
         BE    @@L77
         B     @@L72
@@L19    EQU   *
         L     12,0(,10)
         LA    2,16(0,0)
         CR    7,2
         BH    @@L20
@@L72    EQU   *
         L     12,0(,10)
         MD    4,=D'1.0E+1'
         SLR   2,2
         IC    2,0(15)
         A     2,=F'-240'
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         ADR   4,0
         A     7,=F'1'
         B     @@L77
@@L20    EQU   *
         L     12,0(,10)
         A     8,=F'1'
         B     @@L77
@@L68    EQU   *
         L     12,0(,10)
         CLI   0(15),75
         BNE   @@L23
         A     15,=F'1'
         IC    4,0(15)
         LR    2,4
         N     2,=XL4'000000FF'
         L     5,=V(@@ISBUF)
         L     3,0(5)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BE    @@L23
@@L29    EQU   *
         LTR   7,7
         BNE   @@L27
         CLM   4,1,=XL1'F0'
         BNE   @@L73
         B     @@L75
@@L27    EQU   *
         L     12,0(,10)
         LA    3,16(0,0)
         CR    7,3
         BH    @@L26
@@L73    EQU   *
         L     12,0(,10)
         MD    4,=D'1.0E+1'
         SLR   2,2
         IC    2,0(15)
         A     2,=F'-240'
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         ADR   4,0
         A     7,=F'1'
@@L75    EQU   *
         L     12,0(,10)
         BCTR  8,0
@@L26    EQU   *
         L     12,0(,10)
         A     15,=F'1'
         IC    4,0(15)
         LR    2,4
         N     2,=XL4'000000FF'
         L     3,0(5)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BNE   @@L29
         B     @@L30
@@L23    EQU   *
         L     12,0(,10)
         L     4,96(13)
         LTR   4,4
         BNE   @@L30
         L     2,4(11)
         LTR   2,2
         BE    @@L76
         MVC   0(4,2),0(11)
         B     @@L76
@@L30    EQU   *
         L     12,0(,10)
         IC    2,0(15)
         CLM   2,1,=XL1'85'
         BE    @@L33
         CLM   2,1,=XL1'C5'
         BNE   @@L32
@@L33    EQU   *
         L     12,0(,10)
         LR    4,15
         A     4,=F'1'
         IC    2,0(4)
         CLM   2,1,=XL1'60'
         BNE   @@L34
         MVC   100(4,13),=F'1'
         A     4,=F'1'
         B     @@L35
@@L34    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L35
         LR    4,15
         A     4,=F'2'
@@L35    EQU   *
         L     12,0(,10)
         SLR   5,5
         IC    5,0(4)
         L     3,=V(@@ISBUF)
         L     2,0(3)
         LR    3,5
         AR    3,5
         LH    2,0(3,2)
         N     2,=F'8'
         LTR   2,2
         BE    @@L32
@@L42    EQU   *
         L     2,=F'9999'
         CR    6,2
         BH    @@L40
         LR    2,6
         SLL   2,3
         AR    2,6
         AR    6,2
         AR    6,5
         A     6,=F'-240'
@@L40    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         SLR   5,5
         IC    5,0(4)
         L     3,=V(@@ISBUF)
         L     2,0(3)
         LR    3,5
         AR    3,5
         LH    2,0(3,2)
         N     2,=F'8'
         LTR   2,2
         BNE   @@L42
         LR    15,4
@@L32    EQU   *
         L     12,0(,10)
         L     4,4(11)
         LTR   4,4
         BE    @@L43
         ST    15,0(4)
@@L43    EQU   *
         L     12,0(,10)
         LTR   7,7
         BNE   @@L44
         LD    0,=D'-0.0'
         LTR   9,9
         BNE   @@L9
         B     @@L76
@@L44    EQU   *
         L     12,0(,10)
         LR    3,8
         SR    3,6
         L     2,100(13)
         LTR   2,2
         BNE   @@L48
         LR    3,8
         AR    3,6
@@L48    EQU   *
         L     12,0(,10)
         LR    2,3
         AR    2,7
         BCTR  2,0
         LA    4,75(0,0)
         CR    2,4
         BH    @@L50
         L     4,=F'-79'
         CR    2,4
         BL    @@L52
         LTR   3,3
         BL    @@L53
         ST    3,88(13)
         STD   4,104(13)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         LDR   2,0
         L     2,=V(@DBLMAX)
         LD    0,0(2)
         DDR   0,2
         LD    4,104(13)
         CDR   4,0
         BH    @@L50
         MDR   4,2
         B     @@L56
@@L53    EQU   *
         L     12,0(,10)
         LCR   3,3
         SLR   2,2
         LA    4,64(0,0)
         CR    3,4
         BNH   @@L57
         DD    4,=D'1.00000000000000002132E+64'
         A     3,=F'-64'
         LA    2,1(0,0)
@@L57    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         STD   4,104(13)
         LA    1,88(,13)
         L     15,=A(@@F1)
         BALR  14,15
         LDR   2,0
         LD    4,104(13)
         LTR   2,2
         BE    @@L58
         L     2,=V(@DBLMIN)
         SDR   0,0
         LE    0,0(2)
         MDR   0,2
         CDR   4,0
         BL    @@L52
@@L58    EQU   *
         L     12,0(,10)
         DDR   4,2
@@L56    EQU   *
         L     12,0(,10)
         LDR   0,4
         LTR   9,9
         BE    @@L9
         LCDR  0,4
         B     @@L9
@@L50    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         LD    0,=D'-9.999999999999999830337E+72'
         LTR   9,9
         BNE   @@L9
         LD    0,=D'9.999999999999999830337E+72'
         B     @@L9
@@L52    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         LD    0,=D'-0.0'
         LTR   9,9
         BNE   @@L9
@@L76    EQU   *
         L     12,0(,10)
         LD    0,=D'0.0'
@@L9     EQU   *
         L     12,0(,10)
* Function strtod epilogue
         PDPEPIL
* Function strtod literal pool
         DS    0F
         LTORG
* Function strtod page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
