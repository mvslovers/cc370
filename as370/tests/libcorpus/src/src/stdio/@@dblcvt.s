         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __dblcvt prologue
@@DBLCVT PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __dblcvt code
         SLR   2,2
         SLR   3,3
         ST    2,120(13)
         ST    3,4+120(13)
         ST    2,128(13)
         ST    3,4+128(13)
         ST    2,136(13)
         ST    3,4+136(13)
         ST    2,144(13)
         ST    3,4+144(13)
         LR    8,2
         LR    9,3
         ST    2,152(13)
         ST    3,4+152(13)
         ST    2,160(13)
         ST    3,4+160(13)
         ST    2,168(13)
         ST    3,4+168(13)
         ST    2,176(13)
         ST    3,4+176(13)
         LD    0,0(11)
         L     5,16(11)
         L     2,24(11)
         MVC   104(1,13),11(11)
         LTR   2,2
         L     14,=A(@@L1)
         BER   14
         SLR   15,15
         BCTR  2,0
         ST    2,116(13)
         LTDR  0,0
         BNL   @@L3
         LCDR  2,0
         MVI   112(13),96
         B     @@L5
@@L3     EQU   *
         L     12,0(,10)
         LDR   2,0
         MVI   112(13),64
@@L5     EQU   *
         L     12,0(,10)
         SLR   7,7
         CD    2,=D'1.0E+0'
         BNH   @@L6
         CD    2,=D'1.0E+1'
         BL    @@L12
@@L11    EQU   *
         A     7,=F'1'
         DD    2,=D'1.0E+1'
         CD    2,=D'1.0E+1'
         BL    @@L12
         LA    3,119(0,0)
         CR    7,3
         BNH   @@L11
         B     @@L12
@@L6     EQU   *
         L     12,0(,10)
         LTDR  2,2
         BE    @@L12
         CD    2,=D'1.0E+0'
         BNL   @@L12
         BNL   @@L12
@@L21    EQU   *
         BCTR  7,0
         MD    2,=D'1.0E+1'
         CD    2,=D'1.0E+0'
         BNL   @@L12
         L     4,=F'-120'
         CR    7,4
         BH    @@L21
@@L12    EQU   *
         L     12,0(,10)
         LR    2,7
         A     2,=F'119'
         LA    3,238(0,0)
         CLR   2,3
         BNH   @@L22
         SLR   7,7
         LD    2,=D'0.0'
@@L22    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,104(13)
         LA    4,134(0,0)
         CR    2,4
         BE    @@L27
         BH    @@L37
         LA    3,133(0,0)
         CLR   2,3
         BE    @@L139
         B     @@L30
@@L37    EQU   *
         L     12,0(,10)
         LA    4,197(0,0)
         CLR   2,4
         BE    @@L139
         LA    3,198(0,0)
         CR    2,3
         BNE   @@L30
@@L27    EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'1'
         LTR   7,7
         BNL   @@L40
         MVC   108(4,13),=F'-1'
         B     @@L41
@@L30    EQU   *
         L     12,0(,10)
         LTR   7,7
         BL    @@L31
         MVC   108(4,13),=F'1'
         CR    5,7
         BH    @@L40
         B     @@L139
@@L31    EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'-1'
         L     4,=F'-4'
         CR    7,4
         BNL   @@L41
@@L139   EQU   *
         L     12,0(,10)
         MVC   108(4,13),=F'0'
         LR    3,5
         B     @@L38
@@L40    EQU   *
         L     12,0(,10)
         LR    3,7
         AR    3,5
         B     @@L38
@@L41    EQU   *
         L     12,0(,10)
         LR    3,5
         AR    3,7
@@L38    EQU   *
         L     12,0(,10)
         LA    2,17(0,0)
         CR    3,2
         BNH   @@L42
         LR    3,2
         B     @@L138
@@L42    EQU   *
         L     12,0(,10)
         L     4,=F'-1'
         CR    3,4
         BL    @@L43
@@L138   EQU   *
         L     12,0(,10)
         LTDR  2,2
         BE    @@L43
         LD    0,=D'5.0E+0'
         LTR   3,3
         BL    @@L46
         LD    0,=D'5.0E-1'
@@L46    EQU   *
         L     12,0(,10)
         LA    6,1(0,0)
         LTR   3,3
         BNH   @@L127
@@L49    EQU   *
         DD    0,=D'1.0E+1'
         LR    2,6
         A     6,=F'1'
         CR    2,3
         BL    @@L49
@@L127   EQU   *
         L     12,0(,10)
         ADR   2,0
         CD    2,=D'1.0E+1'
         BL    @@L43
         DD    2,=D'1.0E+1'
         A     7,=F'1'
@@L43    EQU   *
         L     12,0(,10)
         L     3,108(13)
         L     2,=F'-1'
         CR    3,2
         BNE   @@L52
         LTR   7,7
         BL    @@L52
         MVC   108(4,13),=F'1'
@@L52    EQU   *
         L     12,0(,10)
         L     4,116(13)
         L     2,108(13)
         LTR   2,2
         BNE   @@L53
         A     4,=F'-4'
         L     2,116(13)
         LA    3,4(0,0)
         CLR   2,3
         BH    @@L53
         L     4,108(13)
@@L53    EQU   *
         L     12,0(,10)
         IC    3,112(13)
         CLM   3,1,=XL1'60'
         BNE   @@L56
         CLR   15,4
         BNL   @@L56
         L     2,20(11)
         MVC   0(1,2),112(13)
         LA    15,1(0,0)
@@L56    EQU   *
         L     12,0(,10)
         L     2,108(13)
         L     3,=F'-1'
         CLR   2,3
         BNE   @@L59
         CLR   15,4
         BNL   @@L60
         L     8,=F'-16'
         L     3,20(11)
         STC   8,0(3,15)
         A     15,=F'1'
@@L60    EQU   *
         L     12,0(,10)
         CLR   15,4
         BNL   @@L62
         LA    2,75(0,0)
         L     9,20(11)
         STC   2,0(9,15)
@@L144   EQU   *
         A     15,=F'1'
@@L62    EQU   *
         L     12,0(,10)
         A     7,=F'1'
         BE    @@L129
         BCTR  5,0
         CLR   15,4
         BNL   @@L62
         L     8,=F'-16'
         L     3,20(11)
         STC   8,0(3,15)
         B     @@L144
@@L129   EQU   *
         L     12,0(,10)
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         BCTR  5,0
         CLR   15,4
         BNL   @@L69
         ST    6,120(13)
         L     2,120(13)
         L     3,4+120(13)
         SRDA  2,32
         LA    8,10(0,0)
         DR    2,8
         ST    2,120(13)
         ST    3,4+120(13)
         IC    9,123(13)
         LA    2,240(,9)
         L     3,20(11)
         STC   2,0(3,15)
         A     15,=F'1'
@@L69    EQU   *
         L     12,0(,10)
         LR    3,5
         BCTR  3,0
         LTR   5,5
         BNH   @@L76
@@L140   EQU   *
         CLR   15,4
         BNL   @@L76
         MVC   80(4,13),=XL4'4E000000'
         ST    6,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         SDR   2,0
         MD    2,=D'1.0E+1'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         CLR   15,4
         BNL   @@L71
         ST    6,128(13)
         L     8,128(13)
         L     9,4+128(13)
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         ST    8,128(13)
         ST    9,4+128(13)
         LA    2,240(,8)
         L     5,20(11)
         STC   2,0(5,15)
         A     15,=F'1'
@@L71    EQU   *
         L     12,0(,10)
         LR    2,3
         BCTR  3,0
         LTR   2,2
         BNH   @@L76
         B     @@L140
@@L59    EQU   *
         L     12,0(,10)
         L     3,108(13)
         LA    2,1(0,0)
         CLR   3,2
         BNE   @@L77
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         CLR   15,4
         BNL   @@L78
         ST    6,136(13)
         L     2,136(13)
         L     3,4+136(13)
         SRDA  2,32
         LA    8,10(0,0)
         DR    2,8
         ST    2,136(13)
         ST    3,4+136(13)
         IC    9,139(13)
         LA    2,240(,9)
         L     3,20(11)
         STC   2,0(3,15)
         A     15,=F'1'
@@L78    EQU   *
         L     12,0(,10)
         LR    3,5
         AR    3,7
         LR    5,3
         BCTR  3,0
         LTR   5,5
         BNH   @@L76
         CLR   15,4
         BNL   @@L76
         SR    5,3
         BCTR  5,0
@@L87    EQU   *
         CLR   5,7
         BNE   @@L82
         CLR   15,4
         BNL   @@L82
         LA    9,75(0,0)
         L     8,20(11)
         STC   9,0(8,15)
         A     15,=F'1'
@@L82    EQU   *
         L     12,0(,10)
         MVC   80(4,13),=XL4'4E000000'
         ST    6,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         SDR   2,0
         MD    2,=D'1.0E+1'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         CLR   15,4
         BNL   @@L80
         ST    6,144(13)
         L     8,144(13)
         L     9,4+144(13)
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         ST    8,144(13)
         ST    9,4+144(13)
         LA    2,240(,8)
         L     8,20(11)
         STC   2,0(8,15)
         A     15,=F'1'
@@L80    EQU   *
         L     12,0(,10)
         LR    2,3
         BCTR  3,0
         A     5,=F'1'
         LTR   2,2
         BNH   @@L76
         CLR   15,4
         BL    @@L87
         B     @@L76
@@L77    EQU   *
         L     12,0(,10)
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         CLR   15,4
         BNL   @@L89
         LR    8,6
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         LA    2,240(,8)
         L     3,20(11)
         STC   2,0(3,15)
         A     15,=F'1'
@@L89    EQU   *
         L     12,0(,10)
         CLR   15,4
         BNL   @@L91
         LA    9,75(0,0)
         L     8,20(11)
         STC   9,0(8,15)
         A     15,=F'1'
@@L91    EQU   *
         L     12,0(,10)
         LR    3,5
         BCTR  3,0
         LTR   5,5
         BNH   @@L76
@@L141   EQU   *
         CLR   15,4
         BNL   @@L76
         MVC   80(4,13),=XL4'4E000000'
         ST    6,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         SDR   2,0
         MD    2,=D'1.0E+1'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     6,84(,13)
         CLR   15,4
         BNL   @@L93
         ST    6,152(13)
         L     8,152(13)
         L     9,4+152(13)
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         ST    8,152(13)
         ST    9,4+152(13)
         LA    2,240(,8)
         L     5,20(11)
         STC   2,0(5,15)
         A     15,=F'1'
@@L93    EQU   *
         L     12,0(,10)
         LR    2,3
         BCTR  3,0
         LTR   2,2
         BH    @@L141
@@L76    EQU   *
         L     12,0(,10)
         SLR   9,9
         L     8,20(11)
         STC   9,0(15,8)
         L     2,108(13)
         LTR   2,2
         BNE   @@L98
         CL    15,116(13)
         BNL   @@L99
         L     3,=F'-59'
         STC   3,0(8,15)
         A     15,=F'1'
@@L99    EQU   *
         L     12,0(,10)
         LTR   7,7
         BNL   @@L101
         LCR   7,7
         CL    15,116(13)
         BNL   @@L104
         LA    5,96(0,0)
         L     4,20(11)
         STC   5,0(4,15)
         B     @@L142
@@L101   EQU   *
         L     12,0(,10)
         CL    15,116(13)
         BNL   @@L104
         LA    9,78(0,0)
         L     8,20(11)
         STC   9,0(8,15)
@@L142   EQU   *
         L     12,0(,10)
         A     15,=F'1'
@@L104   EQU   *
         L     12,0(,10)
         CL    15,116(13)
         BNL   @@L107
         ST    7,160(13)
         L     4,160(13)
         L     5,4+160(13)
         SRDA  4,32
         LA    8,10(0,0)
         DR    4,8
         ST    4,160(13)
         ST    5,4+160(13)
         ST    5,168(13)
         L     2,168(13)
         L     3,4+168(13)
         SRDA  2,32
         DR    2,8
         ST    2,168(13)
         ST    3,4+168(13)
         IC    5,171(13)
         LA    2,240(,5)
         L     8,20(11)
         STC   2,0(8,15)
         A     15,=F'1'
@@L107   EQU   *
         L     12,0(,10)
         CL    15,116(13)
         BNL   @@L109
         ST    7,176(13)
         L     2,176(13)
         L     3,4+176(13)
         SRDA  2,32
         LA    4,10(0,0)
         DR    2,4
         ST    2,176(13)
         ST    3,4+176(13)
         IC    5,179(13)
         LA    2,240(,5)
         L     8,20(11)
         STC   2,0(8,15)
         A     15,=F'1'
@@L109   EQU   *
         L     12,0(,10)
         SLR   2,2
         L     9,20(11)
         STC   2,0(15,9)
         B     @@L111
@@L98    EQU   *
         L     12,0(,10)
         IC    3,104(13)
         CLM   3,1,=XL1'C7'
         BE    @@L113
         CLM   3,1,=XL1'87'
         BNE   @@L111
@@L113   EQU   *
         L     12,0(,10)
         MVC   88(4,13),20(11)
         MVC   92(4,13),=F'75'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L114
         A     2,=F'1'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         AR    2,15
@@L143   EQU   *
         BCTR  2,0
         CLI   0(2),240
         BNE   @@L134
         MVI   0(2),0
         B     @@L143
@@L134   EQU   *
         L     12,0(,10)
         CLI   0(2),75
         BNE   @@L114
         MVI   0(2),0
@@L114   EQU   *
         L     12,0(,10)
         MVC   88(4,13),20(11)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
@@L111   EQU   *
         L     12,0(,10)
         L     4,12(11)
         CLR   4,15
         BNH   @@L1
         LR    3,4
         SR    3,15
         L     2,116(13)
         SR    2,15
         CLR   3,2
         BNH   @@L120
         LR    3,2
@@L120   EQU   *
         L     12,0(,10)
         L     2,20(11)
         AR    2,3
         ST    2,88(13)
         MVC   92(4,13),20(11)
         A     15,=F'1'
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(MEMMOVE)
         BALR  14,15
         LTR   3,3
         BE    @@L1
@@L123   EQU   *
         BCTR  3,0
         LA    8,64(0,0)
         L     5,20(11)
         STC   8,0(3,5)
         LTR   3,3
         BNE   @@L123
@@L1     EQU   *
         L     12,0(,10)
* Function __dblcvt epilogue
         PDPEPIL
* Function __dblcvt literal pool
         DS    0F
         LTORG
* Function __dblcvt page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
