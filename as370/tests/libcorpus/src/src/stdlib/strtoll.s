         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0123456789abcdefghijklmnopqrstuvwxyz'
         DC    X'0'
         DS    0F
* X-func strtoll prologue
STRTOLL  PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtoll code
         SLR   2,2
         SLR   3,3
         ST    2,144(13)
         ST    3,4+144(13)
         ST    2,152(13)
         ST    3,4+152(13)
         ST    2,160(13)
         ST    3,4+160(13)
         ST    0,112(13)
         L     7,8(11)
         L     6,0(11)
         LR    4,2
         LR    5,3
         MVC   132(4,13),=F'0'
         MVC   136(4,13),132(13)
         MVC   140(4,13),132(13)
         LTR   7,7
         BL    @@L3
         LA    3,1(0,0)
         CR    7,3
         BE    @@L3
         LA    9,36(0,0)
         CR    7,9
         BNH   @@L2
@@L3     EQU   *
         L     12,0(,10)
         L     15,4(11)
         LTR   15,15
         BE    @@L4
         MVC   0(4,15),0(11)
@@L4     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         L     2,112(13)
         MVC   0(8,2),=XL8'0000000000000000'
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         L     3,0(11)
         SLR   2,2
         IC    2,0(3)
         L     3,=V(@@ISBUF)
         L     3,0(3)
@@L59    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L52
         A     6,=F'1'
         SLR   2,2
         IC    2,0(6)
         B     @@L59
@@L52    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'60'
         BNE   @@L8
         MVC   132(4,13),=F'1'
         B     @@L60
@@L8     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L9
@@L60    EQU   *
         L     12,0(,10)
         A     6,=F'1'
@@L9     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L12
         LA    9,16(0,0)
         CLR   7,9
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
         LH    8,0(2,3)
         SLR   3,3
@@L19    EQU   *
         L     2,=A(@V1)
         SLR   15,15
         IC    15,0(3,2)
         CR    15,8
         BE    @@L57
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L19
         B     @@L11
@@L57    EQU   *
         L     12,0(,10)
         LA    9,15(0,0)
         CR    3,9
         BH    @@L11
         A     6,=F'2'
         LA    7,16(0,0)
         B     @@L20
@@L11    EQU   *
         L     12,0(,10)
         LTR   7,7
         BNE   @@L20
         LA    7,8(0,0)
         CLI   0(6),240
         BE    @@L20
         LA    7,10(0,0)
@@L20    EQU   *
         L     12,0(,10)
         LM    2,3,=XL8'8000000000000000'
         ST    2,120(13)
         ST    3,4+120(13)
         L     3,132(13)
         LTR   3,3
         BNE   @@L25
         LM    2,3,=XL8'7FFFFFFFFFFFFFFF'
         ST    2,120(13)
         ST    3,4+120(13)
@@L25    EQU   *
         L     12,0(,10)
         ST    7,144(13)
         L     2,144(13)
         L     3,4+144(13)
         SRDA  2,32
         ST    2,144(13)
         ST    3,4+144(13)
         L     2,120(13)
         L     3,4+120(13)
         ST    2,88(13)
         ST    3,4+88(13)
         L     2,144(13)
         L     3,4+144(13)
         ST    2,96(13)
         ST    3,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@UDIVDI)
         BALR  14,15
         L     8,104(13)
         L     9,4+104(13)
         L     2,120(13)
         L     3,4+120(13)
         ST    2,88(13)
         ST    3,4+88(13)
         L     2,144(13)
         L     3,4+144(13)
         ST    2,96(13)
         ST    3,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@UMODDI)
         BALR  14,15
         MVC   128(4,13),108(13)
@@L26    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    3,0(2,3)
         ST    3,168(13)
         SLR   3,3
@@L34    EQU   *
         L     2,=A(@V1)
         SLR   15,15
         IC    15,0(3,2)
         C     15,168(13)
         BE    @@L58
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L34
         LA    15,36(0,0)
@@L33    EQU   *
         CR    15,7
         BNL   @@L27
         MVC   136(4,13),=F'1'
         L     3,140(13)
         LTR   3,3
         BNE   @@L28
         CLR   4,8
         BH    @@L38
         BNE   @@L39
         CLR   5,9
         BH    @@L38
@@L39    EQU   *
         L     12,0(,10)
         CLR   4,8
         BNE   @@L37
         CR    5,9
         BNE   @@L37
         C     15,128(13)
         BNH   @@L37
@@L38    EQU   *
         L     12,0(,10)
         MVC   140(4,13),=F'1'
         B     @@L28
@@L58    EQU   *
         L     12,0(,10)
         LR    15,3
         B     @@L33
@@L37    EQU   *
         L     12,0(,10)
         ST    7,152(13)
         L     2,152(13)
         L     3,4+152(13)
         SRDA  2,32
         ST    2,152(13)
         ST    3,4+152(13)
         ST    4,88(13)
         ST    5,4+88(13)
         ST    2,96(13)
         ST    3,4+96(13)
         LA    0,104(,13)
         ST    15,176(13)
         LA    1,88(,13)
         L     15,=V(@@MULDI3)
         BALR  14,15
         L     4,104(13)
         L     5,4+104(13)
         L     15,176(13)
         ST    15,160(13)
         L     2,160(13)
         L     3,4+160(13)
         SRDA  2,32
         ST    2,160(13)
         ST    3,4+160(13)
         L     3,164(13)
         AR    3,5
         LA    15,1(0,0)
         CLR   3,5
         BL    @@L40
         SLR   15,15
@@L40    EQU   *
         L     12,0(,10)
         L     2,160(13)
         AR    2,4
         AR    2,15
         LR    4,2
         LR    5,3
@@L28    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L26
@@L27    EQU   *
         L     12,0(,10)
         L     3,4(11)
         LTR   3,3
         BE    @@L41
         LR    2,6
         L     6,136(13)
         LTR   6,6
         BNE   @@L43
         L     2,0(11)
@@L43    EQU   *
         L     12,0(,10)
         L     9,4(11)
         ST    2,0(9)
@@L41    EQU   *
         L     12,0(,10)
         L     15,140(13)
         LTR   15,15
         BE    @@L44
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         LM    2,3,=XL8'8000000000000000'
         L     4,132(13)
         LTR   4,4
         BNE   @@L46
         LM    2,3,=XL8'7FFFFFFFFFFFFFFF'
@@L46    EQU   *
         L     12,0(,10)
         L     6,112(13)
         ST    2,0(6)
         ST    3,4+0(6)
         B     @@L1
@@L44    EQU   *
         L     12,0(,10)
         L     9,132(13)
         LTR   9,9
         BE    @@L47
         L     15,120(13)
         CLR   4,15
         BNE   @@L50
         LM    2,3,=XL8'8000000000000000'
         L     6,124(13)
         CLR   5,6
         BE    @@L49
@@L50    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         ST    5,4+88(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@NEGDI2)
         BALR  14,15
         L     2,104(13)
         L     3,4+104(13)
@@L49    EQU   *
         L     12,0(,10)
         L     9,112(13)
         ST    2,0(9)
         ST    3,4+0(9)
         B     @@L1
@@L47    EQU   *
         L     12,0(,10)
         L     15,112(13)
         ST    4,0(15)
         ST    5,4+0(15)
@@L1     EQU   *
         L     12,0(,10)
         L     15,112(13)
* Function strtoll epilogue
         PDPEPIL
* Function strtoll literal pool
         DS    0F
         LTORG
* Function strtoll page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
