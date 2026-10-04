         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0123456789abcdefghijklmnopqrstuvwxyz'
         DC    X'0'
         DS    0F
* X-func strtoull prologue
STRTOULL PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function strtoull code
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
         ST    2,120(13)
         ST    3,4+120(13)
         MVC   132(4,13),=F'0'
         MVC   136(4,13),132(13)
         MVC   140(4,13),132(13)
         LTR   7,7
         BL    @@L3
         LA    3,1(0,0)
         CR    7,3
         BE    @@L3
         LA    4,36(0,0)
         CR    7,4
         BNH   @@L2
@@L3     EQU   *
         L     12,0(,10)
         L     5,4(11)
         LTR   5,5
         BE    @@L4
         MVC   0(4,5),0(11)
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
@@L52    EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BE    @@L45
         A     6,=F'1'
         SLR   2,2
         IC    2,0(6)
         B     @@L52
@@L45    EQU   *
         L     12,0(,10)
         IC    2,0(6)
         CLM   2,1,=XL1'60'
         BNE   @@L8
         MVC   132(4,13),=F'1'
         B     @@L53
@@L8     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'4E'
         BNE   @@L9
@@L53    EQU   *
         L     12,0(,10)
         A     6,=F'1'
@@L9     EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L12
         LA    4,16(0,0)
         CLR   7,4
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
         LH    4,0(2,3)
         SLR   3,3
@@L19    EQU   *
         L     2,=A(@V1)
         SLR   5,5
         IC    5,0(3,2)
         CR    5,4
         BE    @@L50
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L19
         B     @@L11
@@L50    EQU   *
         L     12,0(,10)
         LA    4,15(0,0)
         CR    3,4
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
         ST    7,144(13)
         L     2,144(13)
         L     3,4+144(13)
         SRDA  2,32
         MVC   88(8,13),=XL8'FFFFFFFFFFFFFFFF'
         ST    2,96(13)
         ST    3,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@UDIVDI)
         BALR  14,15
         L     8,104(13)
         L     9,4+104(13)
         MVC   88(8,13),=XL8'FFFFFFFFFFFFFFFF'
         ST    2,96(13)
         ST    3,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@UMODDI)
         BALR  14,15
         MVC   128(4,13),108(13)
@@L24    EQU   *
         SLR   2,2
         IC    2,0(6)
         L     3,=V(@@TOLOW)
         L     3,0(3)
         AR    2,2
         LH    4,0(2,3)
         SLR   3,3
@@L32    EQU   *
         L     2,=A(@V1)
         SLR   5,5
         IC    5,0(3,2)
         CR    5,4
         BE    @@L51
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L32
         LA    2,36(0,0)
@@L31    EQU   *
         CR    2,7
         BNL   @@L25
         MVC   136(4,13),=F'1'
         L     3,140(13)
         LTR   3,3
         BNE   @@L26
         L     4,120(13)
         CLR   4,8
         BH    @@L36
         BNE   @@L37
         L     3,124(13)
         CLR   3,9
         BH    @@L36
@@L37    EQU   *
         L     12,0(,10)
         L     4,120(13)
         CLR   4,8
         BNE   @@L35
         L     5,124(13)
         CR    5,9
         BNE   @@L35
         C     2,128(13)
         BNH   @@L35
@@L36    EQU   *
         L     12,0(,10)
         MVC   140(4,13),=F'1'
         B     @@L26
@@L51    EQU   *
         L     12,0(,10)
         LR    2,3
         B     @@L31
@@L35    EQU   *
         L     12,0(,10)
         ST    7,152(13)
         L     4,152(13)
         L     5,4+152(13)
         SRDA  4,32
         ST    4,152(13)
         ST    5,4+152(13)
         L     4,120(13)
         L     5,4+120(13)
         ST    4,88(13)
         ST    5,4+88(13)
         L     4,152(13)
         L     5,4+152(13)
         ST    4,96(13)
         ST    5,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@MULDI3)
         BALR  14,15
         L     4,104(13)
         L     5,4+104(13)
         ST    2,160(13)
         L     2,160(13)
         L     3,4+160(13)
         SRDA  2,32
         ST    2,160(13)
         ST    3,4+160(13)
         L     3,164(13)
         AR    3,5
         LA    15,1(0,0)
         CLR   3,5
         BL    @@L38
         SLR   15,15
@@L38    EQU   *
         L     12,0(,10)
         L     2,160(13)
         AR    2,4
         AR    2,15
         ST    2,120(13)
         ST    3,4+120(13)
@@L26    EQU   *
         L     12,0(,10)
         A     6,=F'1'
         B     @@L24
@@L25    EQU   *
         L     12,0(,10)
         L     3,4(11)
         LTR   3,3
         BE    @@L39
         LR    2,6
         L     4,136(13)
         LTR   4,4
         BNE   @@L41
         L     2,0(11)
@@L41    EQU   *
         L     12,0(,10)
         L     5,4(11)
         ST    2,0(5)
@@L39    EQU   *
         L     12,0(,10)
         L     2,140(13)
         LTR   2,2
         BE    @@L42
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'34'
         L     3,112(13)
         MVC   0(8,3),=XL8'FFFFFFFFFFFFFFFF'
         B     @@L1
@@L42    EQU   *
         L     12,0(,10)
         L     2,120(13)
         L     3,4+120(13)
         L     4,132(13)
         LTR   4,4
         BE    @@L43
         ST    2,88(13)
         ST    3,4+88(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@NEGDI2)
         BALR  14,15
         L     2,104(13)
         L     3,4+104(13)
@@L43    EQU   *
         L     12,0(,10)
         L     5,112(13)
         ST    2,0(5)
         ST    3,4+0(5)
@@L1     EQU   *
         L     12,0(,10)
         L     15,112(13)
* Function strtoull epilogue
         PDPEPIL
* Function strtoull literal pool
         DS    0F
         LTORG
* Function strtoull page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
