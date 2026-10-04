         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0123456789abcdefghijklmnopqrstuvwxyz'
         DC    X'0'
         DS    0F
* X-func vvscanf prologue
VVSCANF  PDPPRLG CINDEX=0,FRAME=288,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function vvscanf code
         SLR   2,2
         SLR   3,3
         ST    2,200(13)
         ST    3,4+200(13)
         ST    2,224(13)
         ST    3,4+224(13)
         ST    2,232(13)
         ST    3,4+232(13)
         ST    2,272(13)
         ST    3,4+272(13)
         ST    2,280(13)
         ST    3,4+280(13)
         L     9,8(11)
         L     8,12(11)
         MVC   156(4,13),=F'0'
         MVC   152(4,13),156(13)
         MVC   160(4,13),156(13)
         MVC   164(4,13),156(13)
         MVC   168(4,13),156(13)
         MVC   172(4,13),156(13)
         MVC   176(4,13),156(13)
         MVC   180(4,13),156(13)
         MVC   184(4,13),156(13)
         MVC   188(4,13),156(13)
         LTR   9,9
         BNE   @@L265
         ST    8,180(13)
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L5
@@L265   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FTELL)
         BALR  14,15
         ST    15,176(13)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L5     EQU   *
         L     12,0(,10)
         MVC   192(4,13),=F'0'
@@L246   EQU   *
         L     12,0(,10)
         L     3,0(11)
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BNE   @@L8
         MVC   152(4,13),=F'1'
         L     14,=A(@@L9)
         BR    14
@@L8     EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'6C'
         BE    @@L11
         L     5,192(13)
         LTR   5,5
         L     14,=A(@@L10)
         BER   14
@@L11    EQU   *
         L     12,0(,10)
         CLM   2,1,=XL1'6C'
         BNE   @@L12
         L     6,0(11)
         A     6,=F'1'
         ST    6,0(11)
         MVC   188(4,13),=F'0'
         MVC   184(4,13),188(13)
         CLI   0(6),92
         BNE   @@L12
         MVC   184(4,13),=F'1'
         A     6,=F'1'
         ST    6,0(11)
@@L12    EQU   *
         L     12,0(,10)
         L     7,0(11)
         IC    3,0(7)
         CLM   3,1,=XL1'6C'
         BNE   @@L14
         LA    15,108(0,0)
         CLR   4,15
         L     14,=A(@@L1)
         BNER  14
         LTR   9,9
         BNE   @@L16
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L17
@@L16    EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L17    EQU   *
         L     12,0(,10)
         MVC   192(4,13),=F'0'
         L     14,=A(@@L9)
         BR    14
@@L14    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'93'
         BNE   @@L19
         LA    2,152(0,0)
         L     5,188(13)
         LA    3,147(0,0)
         CLR   5,3
         BE    @@L25
         LR    2,3
         B     @@L25
@@L19    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'88'
         BNE   @@L23
         LA    2,200(0,0)
         L     7,188(13)
         LA    6,136(0,0)
         CLR   7,6
         BE    @@L25
         LR    2,6
@@L25    EQU   *
         L     12,0(,10)
         ST    2,188(13)
         B     @@L285
@@L23    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'91'
         BE    @@L28
         CLM   3,1,=XL1'D3'
         BNE   @@L27
@@L28    EQU   *
         L     12,0(,10)
         MVC   188(4,13),=F'152'
         B     @@L285
@@L27    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'A9'
         BE    @@L31
         CLM   3,1,=XL1'A3'
         BNE   @@L30
@@L31    EQU   *
         L     12,0(,10)
         MVC   188(4,13),=F'147'
@@L285   EQU   *
         L     12,0(,10)
         MVC   192(4,13),=F'1'
         L     14,=A(@@L9)
         BR    14
@@L30    EQU   *
         L     12,0(,10)
         MVC   192(4,13),=F'0'
         CLM   3,1,=XL1'A2'
         BNE   @@L33
         L     15,184(13)
         LTR   15,15
         BNE   @@L34
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         L     2,=F'-4'
         L     3,4(11)
         L     2,0(2,3)
         ST    2,160(13)
@@L34    EQU   *
         L     12,0(,10)
         LTR   4,4
         BL    @@L36
         L     5,=V(@@ISBUF)
@@L277   EQU   *
         L     2,0(5)
         LR    3,4
         AR    3,4
         LH    2,0(3,2)
         N     2,=F'256'
         LTR   2,2
         BE    @@L36
         LTR   9,9
         BNE   @@L37
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L35
@@L37    EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L35    EQU   *
         L     12,0(,10)
         LTR   4,4
         BNL   @@L277
@@L36    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L42
         L     5,=F'-1'
         CLR   4,5
         BE    @@L41
@@L42    EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L289
         LTR   4,4
         BNE   @@L289
@@L41    EQU   *
         L     12,0(,10)
         L     6,184(13)
         LTR   6,6
         L     14,=A(@@L6)
         BNER  14
         L     7,160(13)
         STC   6,0(7)
         L     14,=A(@@L6)
         BR    14
@@L289   EQU   *
         L     12,0(,10)
         L     2,=V(@@ISBUF)
         L     3,0(2)
         LR    2,4
         AR    2,4
         LH    2,0(2,3)
         N     2,=F'256'
         LTR   2,2
         BNE   @@L46
         LTR   9,9
         BE    @@L50
         L     2,=F'-1'
         CLR   4,2
         BE    @@L46
@@L50    EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L48
         LTR   4,4
         BE    @@L46
@@L48    EQU   *
         L     12,0(,10)
         L     3,184(13)
         LTR   3,3
         BNE   @@L51
         L     5,160(13)
         STC   4,0(5)
         A     5,=F'1'
         ST    5,160(13)
@@L51    EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L52
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L289
@@L52    EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
         B     @@L289
@@L46    EQU   *
         L     12,0(,10)
         L     6,184(13)
         LTR   6,6
         L     14,=A(@@L146)
         BNER  14
         L     7,160(13)
         STC   6,0(7)
         L     14,=A(@@L146)
         BR    14
@@L33    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'BA'
         BNE   @@L56
         L     3,192(13)
         LR    6,3
         L     5,184(13)
         LTR   5,5
         BNE   @@L57
         L     7,4(11)
         A     7,=F'4'
         ST    7,4(11)
         L     2,=F'-4'
         L     2,0(2,7)
         ST    2,160(13)
@@L57    EQU   *
         L     12,0(,10)
         L     15,0(11)
         A     15,=F'1'
         ST    15,0(11)
         CLI   0(15),176
         BNE   @@L58
         LA    6,1(0,0)
         AR    15,6
         ST    15,0(11)
@@L58    EQU   *
         L     12,0(,10)
         L     5,0(11)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         L     14,=A(@@L7)
         BER   14
         LR    7,5
         A     7,=F'1'
         ST    7,0(11)
         ST    7,88(13)
         MVC   92(4,13),=F'187'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         L     14,=A(@@L1)
         BER   14
         LR    7,15
         SR    7,5
@@L290   EQU   *
         ST    5,88(13)
         ST    4,92(13)
         ST    7,96(13)
         LA    1,88(,13)
         L     15,=V(MEMCHR)
         BALR  14,15
         LTR   15,15
         BE    @@L64
         LA    15,1(0,0)
         LTR   6,6
         BNE   @@L62
@@L64    EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L65
         LTR   6,6
         BE    @@L62
@@L65    EQU   *
         L     12,0(,10)
         L     15,184(13)
         LTR   15,15
         BNE   @@L66
         L     15,160(13)
         STC   4,0(15)
         A     15,=F'1'
         ST    15,160(13)
@@L66    EQU   *
         L     12,0(,10)
         A     3,=F'1'
         LTR   9,9
         BE    @@L273
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
         L     15,=F'-1'
         CLR   4,15
         BE    @@L62
         B     @@L290
@@L273   EQU   *
         L     12,0(,10)
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         LTR   4,4
         BNE   @@L290
@@L62    EQU   *
         L     12,0(,10)
         LTR   3,3
         L     14,=A(@@L7)
         BER   14
         L     3,184(13)
         LTR   3,3
         BNE   @@L73
         L     5,160(13)
         STC   3,0(5)
         A     5,=F'1'
         ST    5,160(13)
@@L73    EQU   *
         L     12,0(,10)
         L     7,156(13)
         A     7,=F'1'
         ST    7,156(13)
         A     2,=F'1'
         ST    2,0(11)
         L     14,=A(@@L9)
         BR    14
@@L56    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'83'
         BNE   @@L76
         L     15,184(13)
         LTR   15,15
         BNE   @@L77
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         L     2,=F'-4'
         L     3,4(11)
         L     2,0(2,3)
         ST    2,160(13)
@@L77    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L80
         L     5,=F'-1'
         CLR   4,5
         L     14,=A(@@L9)
         BER   14
@@L80    EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L78
         LTR   4,4
         L     14,=A(@@L9)
         BER   14
@@L78    EQU   *
         L     12,0(,10)
         L     6,184(13)
         LTR   6,6
         BNE   @@L82
         L     7,160(13)
         STC   4,0(7)
@@L82    EQU   *
         L     12,0(,10)
         L     15,156(13)
         A     15,=F'1'
         ST    15,156(13)
         L     14,=A(@@L288)
         BR    14
@@L76    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'95'
         BNE   @@L86
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         L     2,=F'-4'
         L     3,4(11)
         L     2,0(2,3)
         ST    2,164(13)
         LTR   9,9
         BE    @@L87
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FTELL)
         BALR  14,15
         S     15,176(13)
         B     @@L88
@@L87    EQU   *
         L     12,0(,10)
         LR    15,8
         S     15,180(13)
         BCTR  15,0
@@L88    EQU   *
         L     12,0(,10)
         L     6,188(13)
         LA    5,147(0,0)
         CR    6,5
         BE    @@L94
         BH    @@L95
         LA    7,136(0,0)
         CLR   6,7
         BE    @@L91
         B     @@L94
@@L95    EQU   *
         L     12,0(,10)
         L     3,188(13)
         LA    2,152(0,0)
         CLR   3,2
         BE    @@L93
         LA    5,200(0,0)
         CLR   3,5
         BNE   @@L94
         L     6,164(13)
         STC   15,0(6)
         L     14,=A(@@L9)
         BR    14
@@L91    EQU   *
         L     12,0(,10)
         L     7,164(13)
         STH   15,0(7)
         L     14,=A(@@L9)
         BR    14
@@L93    EQU   *
         L     12,0(,10)
         ST    15,200(13)
         L     6,200(13)
         L     7,4+200(13)
         SRDA  6,32
         ST    6,200(13)
         ST    7,4+200(13)
         L     15,164(13)
         ST    6,0(15)
         ST    7,4+0(15)
         L     14,=A(@@L9)
         BR    14
@@L94    EQU   *
         L     12,0(,10)
         L     2,164(13)
         ST    15,0(2)
         L     14,=A(@@L9)
         BR    14
@@L86    EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'84'
         BE    @@L98
         CLM   3,1,=XL1'A4'
         BE    @@L98
         CLM   3,1,=XL1'A7'
         BE    @@L98
         CLM   3,1,=XL1'96'
         BE    @@L98
         CLM   3,1,=XL1'97'
         BE    @@L98
         CLM   3,1,=XL1'89'
         L     14,=A(@@L97)
         BNER  14
@@L98    EQU   *
         L     12,0(,10)
         MVC   208(4,13),=F'0'
         SLR   6,6
         SLR   7,7
         MVC   212(4,13),208(13)
         MVC   216(4,13),=F'10'
         MVC   220(4,13),208(13)
         CLM   3,1,=XL1'A7'
         BE    @@L278
         CLM   3,1,=XL1'97'
         BNE   @@L101
@@L278   EQU   *
         L     12,0(,10)
         MVC   216(4,13),=F'16'
         B     @@L100
@@L101   EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'96'
         BNE   @@L103
         MVC   216(4,13),=F'8'
         B     @@L100
@@L103   EQU   *
         L     12,0(,10)
         CLM   3,1,=XL1'89'
         BNE   @@L100
         MVC   216(4,13),208(13)
@@L100   EQU   *
         L     12,0(,10)
         L     3,184(13)
         LTR   3,3
         BNE   @@L106
         L     5,4(11)
         A     5,=F'4'
         ST    5,4(11)
         L     2,=F'-4'
         L     2,0(2,5)
         ST    2,164(13)
@@L106   EQU   *
         L     12,0(,10)
         LTR   4,4
         BL    @@L108
         L     5,=V(@@ISBUF)
@@L279   EQU   *
         L     2,0(5)
         LR    3,4
         AR    3,4
         LH    2,0(3,2)
         N     2,=F'256'
         LTR   2,2
         BE    @@L108
         LTR   9,9
         BNE   @@L109
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L107
@@L109   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L107   EQU   *
         L     12,0(,10)
         LTR   4,4
         BNL   @@L279
@@L108   EQU   *
         L     12,0(,10)
         LA    15,96(0,0)
         CLR   4,15
         BNE   @@L112
         MVC   208(4,13),=F'1'
         B     @@L286
@@L112   EQU   *
         L     12,0(,10)
         LA    2,78(0,0)
         CLR   4,2
         BNE   @@L115
@@L286   EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L117
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L115
@@L117   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L115   EQU   *
         L     12,0(,10)
         L     3,216(13)
         LTR   3,3
         BNE   @@L291
         MVC   212(4,13),=F'1'
         B     @@L291
@@L144   EQU   *
         LA    5,167(0,0)
         CLR   4,5
         BE    @@L125
         LA    15,231(0,0)
         CLR   4,15
         BNE   @@L124
@@L125   EQU   *
         L     12,0(,10)
         L     3,220(13)
         LA    2,1(0,0)
         CLR   3,2
         BNE   @@L124
         LR    2,6
         OR    2,7
         LTR   2,2
         BNE   @@L124
         L     15,216(13)
         LA    5,16(0,0)
         CLR   15,5
         BE    @@L126
         LA    3,8(0,0)
         CLR   15,3
         BNE   @@L124
         L     5,212(13)
         LTR   5,5
         BE    @@L124
@@L126   EQU   *
         L     12,0(,10)
         MVC   216(4,13),=F'16'
         ST    2,212(13)
         LTR   9,9
         BNE   @@L127
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L263
@@L127   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
         B     @@L291
@@L258   EQU   *
         LR    2,3
         B     @@L133
@@L124   EQU   *
         L     12,0(,10)
         L     2,=V(@@TOLOW)
         L     3,0(2)
         LR    2,4
         AR    2,4
         LH    5,0(2,3)
         SLR   3,3
@@L134   EQU   *
         L     2,=A(@V1)
         SLR   15,15
         IC    15,0(3,2)
         CR    15,5
         BE    @@L258
         A     3,=F'1'
         LA    2,35(0,0)
         CR    3,2
         BNH   @@L134
         LA    2,36(0,0)
@@L133   EQU   *
         L     12,0(,10)
         L     3,216(13)
         LTR   3,3
         BNE   @@L135
         LA    5,9(0,0)
         CR    2,5
         BH    @@L121
         MVC   216(4,13),=F'8'
         LA    15,240(0,0)
         CR    4,15
         BE    @@L135
         MVC   216(4,13),=F'10'
         MVC   212(4,13),=F'0'
@@L135   EQU   *
         L     12,0(,10)
         C     2,216(13)
         BNL   @@L121
         L     3,216(13)
         ST    3,224(13)
         L     4,224(13)
         L     5,4+224(13)
         SRDA  4,32
         ST    4,224(13)
         ST    5,4+224(13)
         ST    6,88(13)
         ST    7,4+88(13)
         ST    4,96(13)
         ST    5,4+96(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@MULDI3)
         BALR  14,15
         L     4,104(13)
         L     5,4+104(13)
         ST    2,232(13)
         L     6,232(13)
         L     7,4+232(13)
         SRDA  6,32
         ST    6,232(13)
         ST    7,4+232(13)
         L     3,236(13)
         AR    3,5
         LA    6,1(0,0)
         CLR   3,5
         BL    @@L141
         SLR   6,6
@@L141   EQU   *
         L     12,0(,10)
         L     2,232(13)
         AR    2,4
         AR    2,6
         LR    6,2
         LR    7,3
         LTR   9,9
         BNE   @@L142
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L143
@@L142   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L143   EQU   *
         L     12,0(,10)
         L     15,220(13)
         A     15,=F'1'
         ST    15,220(13)
@@L291   EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L122
         L     2,=F'-1'
         CLR   4,2
         BE    @@L121
@@L122   EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L144
@@L263   EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L144
@@L121   EQU   *
         L     12,0(,10)
         L     3,220(13)
         LTR   3,3
         L     14,=A(@@L7)
         BER   14
         L     5,184(13)
         LTR   5,5
         L     14,=A(@@L146)
         BNER  14
         L     15,208(13)
         LTR   15,15
         BE    @@L147
         ST    6,88(13)
         ST    7,4+88(13)
         LA    0,104(,13)
         LA    1,88(,13)
         L     15,=V(@@NEGDI2)
         BALR  14,15
         L     6,104(13)
         L     7,4+104(13)
@@L147   EQU   *
         L     12,0(,10)
         L     3,0(11)
         IC    2,0(3)
         CLM   2,1,=XL1'84'
         BE    @@L149
         CLM   2,1,=XL1'89'
         BNE   @@L148
@@L149   EQU   *
         L     12,0(,10)
         L     15,188(13)
         LA    5,147(0,0)
         CR    15,5
         BE    @@L153
         BH    @@L156
         LA    2,136(0,0)
         CLR   15,2
         BE    @@L152
         B     @@L155
@@L156   EQU   *
         L     12,0(,10)
         L     5,188(13)
         LA    3,152(0,0)
         CLR   5,3
         BE    @@L154
         LA    15,200(0,0)
         CLR   5,15
         BNE   @@L155
         L     2,164(13)
         STC   7,0(2)
         B     @@L146
@@L152   EQU   *
         L     12,0(,10)
         L     3,164(13)
         STH   7,0(3)
         B     @@L146
@@L153   EQU   *
         L     12,0(,10)
         L     5,164(13)
         ST    7,0(5)
         B     @@L146
@@L154   EQU   *
         L     12,0(,10)
         L     15,164(13)
         ST    6,0(15)
         ST    7,4+0(15)
         B     @@L146
@@L155   EQU   *
         L     12,0(,10)
         L     2,164(13)
         ST    7,0(2)
         B     @@L146
@@L148   EQU   *
         L     12,0(,10)
         L     5,188(13)
         LA    3,147(0,0)
         CR    5,3
         BE    @@L161
         BH    @@L164
         LA    15,136(0,0)
         CLR   5,15
         BE    @@L160
         B     @@L163
@@L164   EQU   *
         L     12,0(,10)
         L     3,188(13)
         LA    2,152(0,0)
         CLR   3,2
         BE    @@L162
         LA    5,200(0,0)
         CLR   3,5
         BNE   @@L163
         L     15,164(13)
         STC   7,0(15)
         B     @@L146
@@L160   EQU   *
         L     12,0(,10)
         L     2,164(13)
         STH   7,0(2)
         B     @@L146
@@L161   EQU   *
         L     12,0(,10)
         L     3,164(13)
         ST    7,0(3)
         B     @@L146
@@L162   EQU   *
         L     12,0(,10)
         L     5,164(13)
         ST    6,0(5)
         ST    7,4+0(5)
         B     @@L146
@@L163   EQU   *
         L     12,0(,10)
         L     15,164(13)
         ST    7,0(15)
@@L146   EQU   *
         L     12,0(,10)
         L     2,156(13)
         A     2,=F'1'
         ST    2,156(13)
         L     14,=A(@@L9)
         BR    14
@@L97    EQU   *
         L     12,0(,10)
         LA    2,123(,3)
         CLM   2,1,=XL1'02'
         BNH   @@L167
         CLM   3,1,=XL1'C5'
         BE    @@L167
         CLM   3,1,=XL1'C7'
         L     14,=A(@@L9)
         BNER  14
@@L167   EQU   *
         L     12,0(,10)
         MVC   240(4,13),=F'0'
         MVC   244(4,13),240(13)
         MVC   248(4,13),240(13)
         SLR   7,7
         ST    7,252(13)
         ST    7,256(13)
         LR    6,7
         ST    7,260(13)
         LR    5,7
         ST    7,264(13)
         L     3,184(13)
         LTR   3,3
         BNE   @@L168
         L     2,188(13)
         LA    15,147(0,0)
         CLR   2,15
         BE    @@L170
         LA    3,152(0,0)
         CLR   2,3
         BNE   @@L169
@@L170   EQU   *
         L     12,0(,10)
         L     15,4(11)
         A     15,=F'4'
         ST    15,4(11)
         L     2,=F'-4'
         L     2,0(2,15)
         ST    2,168(13)
         B     @@L168
@@L169   EQU   *
         L     12,0(,10)
         L     2,4(11)
         A     2,=F'4'
         ST    2,4(11)
         L     2,=F'-4'
         L     3,4(11)
         L     2,0(2,3)
         ST    2,172(13)
@@L168   EQU   *
         L     12,0(,10)
         LTR   4,4
         BL    @@L173
         L     15,=V(@@ISBUF)
         L     2,0(15)
@@L281   EQU   *
         LR    3,4
         AR    3,4
         LH    2,0(3,2)
         N     2,=F'256'
         LTR   2,2
         BE    @@L173
         LTR   9,9
         BNE   @@L174
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L172
@@L174   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L172   EQU   *
         L     12,0(,10)
         LTR   4,4
         BL    @@L173
         L     3,=V(@@ISBUF)
         L     2,0(3)
         B     @@L281
@@L173   EQU   *
         L     12,0(,10)
         LA    15,96(0,0)
         CLR   4,15
         BNE   @@L177
         MVC   240(4,13),=F'1'
         B     @@L287
@@L177   EQU   *
         L     12,0(,10)
         LA    2,78(0,0)
         CLR   4,2
         BNE   @@L180
@@L287   EQU   *
         L     12,0(,10)
         LTR   9,9
         BNE   @@L182
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L180
@@L182   EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L180   EQU   *
         L     12,0(,10)
         LTR   4,4
         L     14,=A(@@L1)
         BNHR  14
@@L209   EQU   *
         L     12,0(,10)
         LA    3,75(0,0)
         CLR   4,3
         BNE   @@L186
         L     15,248(13)
         LTR   15,15
         BNE   @@L186
         LTR   7,7
         BNE   @@L186
         MVC   248(4,13),=F'1'
         L     14,=A(@@L187)
         BR    14
@@L186   EQU   *
         L     12,0(,10)
         L     2,=V(@@ISBUF)
         L     3,0(2)
         LR    2,4
         AR    2,4
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         L     14,=A(@@L188)
         BER   14
         LTR   7,7
         L     14,=A(@@L189)
         BER   14
         B     @@PGE0
         DS    0F
         LTORG
         DS    0F
@@PGE0   EQU   *
         DROP  12
         BASR  12,0
         USING *,12
@@PG1    EQU   *
         L     2,256(13)
         A     2,=F'1'
         ST    2,256(13)
         L     3,=F'9999'
         CR    5,3
         BH    @@L187
         LR    2,5
         SLL   2,3
         AR    2,5
         AR    5,2
         AR    5,4
         A     5,=F'-240'
         B     @@L187
@@L189   EQU   *
         L     12,4(,10)
         L     15,252(13)
         A     15,=F'1'
         ST    15,252(13)
         LTR   6,6
         BNE   @@L192
         LA    2,240(0,0)
         CLR   4,2
         BNE   @@L264
         L     3,248(13)
         LTR   3,3
         BE    @@L187
         L     4,264(13)
         BCTR  4,0
         ST    4,264(13)
         B     @@L187
@@L192   EQU   *
         L     12,4(,10)
         LA    15,16(0,0)
         CR    6,15
         BH    @@L195
@@L264   EQU   *
         L     12,4(,10)
         STC   4,112(6,13)
         A     6,=F'1'
         L     2,248(13)
         LTR   2,2
         BE    @@L187
         L     3,264(13)
         BCTR  3,0
         ST    3,264(13)
         B     @@L187
@@L195   EQU   *
         L     12,4(,10)
         L     4,248(13)
         LTR   4,4
         BNE   @@L187
         L     15,264(13)
         A     15,=F'1'
         ST    15,264(13)
         B     @@L187
@@L188   EQU   *
         L     12,4(,10)
         LA    2,133(0,0)
         CLR   4,2
         BE    @@L201
         LA    3,197(0,0)
         CLR   4,3
         BNE   @@L200
@@L201   EQU   *
         L     12,4(,10)
         LTR   7,7
         BNE   @@L200
         LA    7,1(0,0)
         B     @@L187
@@L200   EQU   *
         L     12,4(,10)
         LA    15,78(0,0)
         CLR   4,15
         BE    @@L204
         LA    2,96(0,0)
         CLR   4,2
         BNE   @@L185
@@L204   EQU   *
         L     12,4(,10)
         LA    3,1(0,0)
         CLR   7,3
         BNE   @@L185
         L     15,256(13)
         LTR   15,15
         BNE   @@L185
         L     2,260(13)
         LTR   2,2
         BNE   @@L185
         ST    7,260(13)
         LA    3,96(0,0)
         CLR   4,3
         BNE   @@L187
         ST    7,244(13)
@@L187   EQU   *
         L     12,4(,10)
         LTR   9,9
         BNE   @@L207
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L184
@@L207   EQU   *
         L     12,4(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L184   EQU   *
         L     12,4(,10)
         LTR   4,4
         L     14,=A(@@L209)
         BHR   14
@@L185   EQU   *
         L     12,4(,10)
         L     15,252(13)
         LTR   15,15
         BE    @@L1
         LTR   7,7
         BE    @@L210
         L     2,256(13)
         LTR   2,2
         BE    @@L1
@@L210   EQU   *
         L     12,4(,10)
         LD    4,=D'0.0'
         LTR   6,6
         BE    @@L213
         L     3,244(13)
         LTR   3,3
         BE    @@L214
         L     7,264(13)
         SR    7,5
         LR    5,7
         B     @@L215
@@L214   EQU   *
         L     12,4(,10)
         A     5,264(13)
@@L215   EQU   *
         L     12,4(,10)
         LA    3,112(,13)
         AR    3,6
         MVI   0(3),133
         A     3,=F'1'
         LTR   5,5
         BNL   @@L216
         MVI   0(3),96
         A     3,=F'1'
         LCR   5,5
@@L216   EQU   *
         L     12,4(,10)
         SLR   15,15
@@L217   EQU   *
         ST    5,272(13)
         L     6,272(13)
         L     7,4+272(13)
         SRDA  6,32
         LA    2,10(0,0)
         DR    6,2
         ST    6,272(13)
         ST    7,4+272(13)
         LA    2,240(,6)
         STC   2,0(3,15)
         A     15,=F'1'
         ST    5,280(13)
         L     6,280(13)
         L     7,4+280(13)
         SRDA  6,32
         LA    2,10(0,0)
         DR    6,2
         ST    6,280(13)
         ST    7,4+280(13)
         LR    5,7
         L     6,284(13)
         LTR   6,6
         BH    @@L217
         SLR   7,7
         STC   7,0(15,3)
         BCTR  15,0
         SLR   6,6
         CR    6,15
         BNL   @@L256
         LR    5,15
         AR    5,3
@@L223   EQU   *
         IC    2,0(3)
         MVC   0(1,3),0(5)
         STC   2,0(5)
         A     6,=F'1'
         A     3,=F'1'
         BCTR  15,0
         BCTR  5,0
         CR    6,15
         BL    @@L223
@@L256   EQU   *
         L     12,4(,10)
         LA    15,112(,13)
         ST    15,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(STRTOD)
         BALR  14,15
         LDR   4,0
@@L213   EQU   *
         L     12,4(,10)
         L     2,240(13)
         LTR   2,2
         BE    @@L224
         LCDR  4,4
@@L224   EQU   *
         L     12,4(,10)
         L     3,184(13)
         LTR   3,3
         BNE   @@L225
         L     6,188(13)
         LA    5,147(0,0)
         CLR   6,5
         BE    @@L227
         LA    7,152(0,0)
         CLR   6,7
         BNE   @@L226
@@L227   EQU   *
         L     12,4(,10)
         L     15,168(13)
         STD   4,0(15)
         B     @@L225
@@L226   EQU   *
         L     12,4(,10)
         L     2,=V(@FLTMAX)
         LE    2,0(2)
         SDR   0,0
         LER   0,2
         CDR   4,0
         BNH   @@L229
         L     2,172(13)
         STE   2,0(2)
         B     @@L225
@@L229   EQU   *
         L     12,4(,10)
         LCER  2,2
         SDR   0,0
         LER   0,2
         CDR   4,0
         BNL   @@L232
         L     3,172(13)
         STE   2,0(3)
         B     @@L225
@@L232   EQU   *
         L     12,4(,10)
         LRER  0,4
         L     5,172(13)
         STE   0,0(5)
@@L225   EQU   *
         L     12,4(,10)
         L     6,156(13)
         A     6,=F'1'
         ST    6,156(13)
         B     @@L9
@@L10    EQU   *
         L     12,4(,10)
         LR    3,2
         N     3,=XL4'000000FF'
         L     6,=V(@@ISBUF)
         L     5,0(6)
         LR    2,3
         AR    2,3
         LH    2,0(2,5)
         N     2,=F'256'
         LTR   2,2
         BE    @@L236
         LTR   4,4
         BL    @@L9
         LR    2,4
         AR    2,4
         LH    2,0(2,5)
@@L283   EQU   *
         N     2,=F'256'
         LTR   2,2
         BE    @@L9
         LTR   9,9
         BNE   @@L239
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L237
@@L239   EQU   *
         L     12,4(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L237   EQU   *
         L     12,4(,10)
         LTR   4,4
         BL    @@L9
         L     2,0(6)
         LR    3,4
         AR    3,4
         LH    2,0(3,2)
         B     @@L283
@@L236   EQU   *
         L     12,4(,10)
         CLR   4,3
         BNE   @@L1
@@L288   EQU   *
         L     12,4(,10)
         LTR   9,9
         BNE   @@L244
         SLR   4,4
         IC    4,0(8)
         A     8,=F'1'
         B     @@L9
@@L244   EQU   *
         L     12,4(,10)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FGETC)
         BALR  14,15
         LR    4,15
@@L9     EQU   *
         L     12,4(,10)
         L     7,0(11)
         A     7,=F'1'
         ST    7,0(11)
@@L6     EQU   *
         L     12,4(,10)
         L     15,152(13)
         LTR   15,15
         L     14,=A(@@L246)
         BER   14
@@L7     EQU   *
         L     12,4(,10)
         LTR   9,9
         BE    @@L1
         ST    4,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(UNGETC)
         BALR  14,15
@@L1     EQU   *
         L     12,4(,10)
         L     15,156(13)
* Function vvscanf epilogue
         PDPEPIL
* Function vvscanf literal pool
         DS    0F
         LTORG
* Function vvscanf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DC    A(@@PG1)
         END
