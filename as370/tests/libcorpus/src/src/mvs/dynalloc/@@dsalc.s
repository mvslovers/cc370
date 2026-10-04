         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C';'
         DC    X'0'
@@LC1    EQU   *
         DC    C'MOUNT'
         DC    X'0'
@@LC2    EQU   *
         DC    C'BLKSIZE='
         DC    X'0'
@@LC3    EQU   *
         DC    C'DD='
         DC    X'0'
@@LC4    EQU   *
         DC    C'DDNAME='
         DC    X'0'
@@LC5    EQU   *
         DC    C'DISP='
         DC    X'0'
@@LC6    EQU   *
         DC    C'DCBDSN='
         DC    X'0'
@@LC7    EQU   *
         DC    C'DSN='
         DC    X'0'
@@LC8    EQU   *
         DC    C'DSNAME='
         DC    X'0'
@@LC9    EQU   *
         DC    C'DSORG='
         DC    X'0'
@@LC10   EQU   *
         DC    C'RECFM='
         DC    X'0'
@@LC11   EQU   *
         DC    C'LRECL='
         DC    X'0'
@@LC12   EQU   *
         DC    C'SPACE='
         DC    X'0'
@@LC13   EQU   *
         DC    C'UNIT='
         DC    X'0'
@@LC14   EQU   *
         DC    C'VOLSER='
         DC    X'0'
@@LC15   EQU   *
         DC    C' ,'
         DC    X'0'
@@LC16   EQU   *
         DC    C'NEW'
         DC    X'0'
@@LC17   EQU   *
         DC    C'OLD'
         DC    X'0'
@@LC18   EQU   *
         DC    C'MOD'
         DC    X'0'
@@LC19   EQU   *
         DC    C'SHR'
         DC    X'0'
@@LC20   EQU   *
         DC    C'DEL'
         DC    X'0'
@@LC21   EQU   *
         DC    C'DELETE'
         DC    X'0'
@@LC22   EQU   *
         DC    C'CAT'
         DC    X'0'
@@LC23   EQU   *
         DC    C'CATLG'
         DC    X'0'
@@LC24   EQU   *
         DC    C'KEEP'
         DC    X'0'
@@LC25   EQU   *
         DC    C'UNCAT'
         DC    X'0'
@@LC26   EQU   *
         DC    C'UNCATLG'
         DC    X'0'
@@LC27   EQU   *
         DC    C'CYL='
         DC    X'0'
@@LC28   EQU   *
         DC    C'TRK='
         DC    X'0'
         DS    0F
* X-func __dsalc prologue
@@DSALC  PDPPRLG CINDEX=0,FRAME=184,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __dsalc code
         L     8,4(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         ST    15,172(13)
         LA    6,1(0,0)
         SLR   9,9
         LA    4,96(,13)
         LA    5,48(0,0)
         LR    2,9
         LR    3,9
         MVCL  4,2
         LA    7,96(,13)
         ST    9,168(13)
         LA    2,144(,13)
         LR    4,2
         LA    5,20(0,0)
         LR    2,9
         LR    3,9
         MVCL  4,2
         LR    15,6
         L     3,172(13)
         LTR   3,3
         L     14,=A(@@L1)
         BER   14
         MVC   176(4,13),276(3)
         LTR   8,8
         BE    @@L3
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         A     15,=F'8'
         ST    6,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    9,15
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         LR    4,15
         LR    5,8
@@L147   EQU   *
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BE    @@L140
         SLR   2,2
         IC    2,0(5)
         L     3,=V(@@TOUP)
         L     3,0(3)
         AR    2,2
         IC    3,1(2,3)
         STC   3,0(4)
         A     4,=F'1'
         A     5,=F'1'
         B     @@L147
@@L140   EQU   *
         L     12,0(,10)
         LR    4,9
         IC    2,0(9)
@@L148   EQU   *
         CLM   2,1,=XL1'00'
         BE    @@L3
         CLI   0(4),77
         BNE   @@L13
         L     2,=F'-1'
         IC    2,0(2,4)
         CLM   2,1,=XL1'7E'
         BE    @@L14
         MVI   0(4),126
         B     @@L15
@@L146   EQU   *
         ST    4,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         B     @@L13
@@L14    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         A     4,=F'1'
         ST    4,92(13)
         BCTR  4,0
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
@@L15    EQU   *
         L     12,0(,10)
         A     4,=F'1'
@@L149   EQU   *
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L13
         LR    2,4
         A     2,=F'1'
         CLI   0(4),93
         BE    @@L146
         LR    4,2
         B     @@L149
@@L13    EQU   *
         L     12,0(,10)
         CLI   0(4),107
         BNE   @@L12
         MVI   0(4),94
@@L12    EQU   *
         L     12,0(,10)
         A     4,=F'1'
         IC    2,0(4)
         B     @@L148
@@L3     EQU   *
         L     12,0(,10)
         ST    9,88(13)
@@L150   EQU   *
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L144
         L     2,=A(@@LC1)
         CLC   0(6,15),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BNE   @@L26
         MVC   44(4,7),=F'1'
         B     @@L25
@@L26    EQU   *
         L     12,0(,10)
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC2)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L28
         A     4,=F'8'
         ST    4,0(7)
         B     @@L25
@@L28    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L30
         A     4,=F'3'
         B     @@L152
@@L30    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC4)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L32
         A     4,=F'7'
@@L152   EQU   *
         L     12,0(,10)
         ST    4,4(7)
         B     @@L25
@@L32    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L34
         A     4,=F'5'
         ST    4,8(7)
         B     @@L25
@@L34    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC6)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L36
         A     4,=F'7'
         ST    4,12(7)
         B     @@L25
@@L36    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC7)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L38
         A     4,=F'4'
         B     @@L151
@@L38    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC8)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L40
         A     4,=F'7'
@@L151   EQU   *
         L     12,0(,10)
         ST    4,16(7)
         B     @@L25
@@L40    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC9)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L42
         A     4,=F'6'
         ST    4,20(7)
         B     @@L25
@@L42    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC10)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L44
         A     4,=F'6'
         ST    4,28(7)
         B     @@L25
@@L44    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC11)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L46
         A     4,=F'6'
         ST    4,24(7)
         B     @@L25
@@L46    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC12)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L48
         A     4,=F'6'
         ST    4,32(7)
         B     @@L25
@@L48    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC13)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L50
         A     4,=F'5'
         ST    4,36(7)
         B     @@L25
@@L50    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC14)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L25
         A     4,=F'7'
         ST    4,40(7)
@@L25    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         B     @@L150
@@L144   EQU   *
         L     12,0(,10)
         L     3,4(7)
         LTR   3,3
         BE    @@L54
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L54
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDDN)
         BALR  14,15
         B     @@L153
@@L54    EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
@@L153   EQU   *
         L     12,0(,10)
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
         L     3,16(7)
         LTR   3,3
         BE    @@L57
         IC    2,0(3)
         CLM   2,1,=XL1'00'
         BE    @@L57
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L57    EQU   *
         L     12,0(,10)
         L     2,8(7)
         LTR   2,2
         L     14,=A(@@L59)
         BER   14
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC15)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L161
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L161
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC16)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L63
@@L161   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@TXNEW)
         BALR  14,15
         B     @@L154
@@L63    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC17)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L65
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXOLD)
         BALR  14,15
         B     @@L154
@@L65    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC18)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L67
         LA    2,168(,13)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXMOD)
         BALR  14,15
         B     @@L154
@@L67    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC19)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LA    6,1(0,0)
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSHR)
         BALR  14,15
@@L154   EQU   *
         L     12,0(,10)
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC15)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L72
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC20)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L162
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC21)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L75
@@L162   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDEL)
         BALR  14,15
         B     @@L156
@@L75    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC22)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L163
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC23)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L79
@@L163   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCAT)
         BALR  14,15
         B     @@L156
@@L79    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC24)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L81
         LA    2,168(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXKEEP)
         BALR  14,15
         B     @@L156
@@L81    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC25)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BNE   @@L155
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC26)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LTR   15,15
         BE    @@L85
@@L155   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         ST    6,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXUCAT)
         BALR  14,15
         B     @@L156
@@L85    EQU   *
         L     12,0(,10)
         LA    6,1(0,0)
         L     14,=A(@@L5)
         BR    14
@@L156   EQU   *
         L     12,0(,10)
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L72    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@LC15)
         LA    1,88(,13)
         L     15,=V(STRTOK)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L59
         ST    15,88(13)
         MVC   92(4,13),=A(@@LC20)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L89
         LA    2,168(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         B     @@L164
@@L89    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC21)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L91
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
@@L164   EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@TXADEL)
         BALR  14,15
         B     @@L158
@@L91    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC22)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L93
         LA    2,168(,13)
         ST    2,88(13)
         ST    5,92(13)
         B     @@L165
@@L93    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC23)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L95
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
@@L165   EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@TXACAT)
         BALR  14,15
         B     @@L158
@@L95    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC24)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L97
         LA    2,168(,13)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXAKEE)
         BALR  14,15
         B     @@L158
@@L97    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC25)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L99
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         B     @@L157
@@L99    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC26)
         LA    1,88(,13)
         L     15,=V(STRSTR)
         BALR  14,15
         LA    6,1(0,0)
         LTR   15,15
         L     14,=A(@@L5)
         BER   14
         LA    2,168(,13)
         ST    2,88(13)
         ST    5,92(13)
@@L157   EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@TXAUCA)
         BALR  14,15
@@L158   EQU   *
         L     12,0(,10)
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L59    EQU   *
         L     12,0(,10)
         L     3,12(7)
         LTR   3,3
         BE    @@L104
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXDCBD)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L104   EQU   *
         L     12,0(,10)
         L     3,20(7)
         LTR   3,3
         BE    @@L106
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXORG)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L106   EQU   *
         L     12,0(,10)
         L     3,28(7)
         LTR   3,3
         BE    @@L108
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRECF)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L108   EQU   *
         L     12,0(,10)
         L     3,24(7)
         LTR   3,3
         BE    @@L110
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXLREC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L110   EQU   *
         L     12,0(,10)
         L     3,0(7)
         LTR   3,3
         BE    @@L112
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXBKSZ)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L112   EQU   *
         L     12,0(,10)
         L     3,32(7)
         LTR   3,3
         L     14,=A(@@L114)
         BER   14
         L     2,=A(@@LC27)
         CLC   0(4,3),0(2)
         LA    4,1(0,0)
         BH    *+12
         BL    *+6
         SLR   4,4
         LNR   4,4
         LTR   4,4
         BNE   @@L115
         LA    2,168(,13)
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCYL)
         BALR  14,15
         B     @@L167
@@L115   EQU   *
         L     12,0(,10)
         L     2,=A(@@LC28)
         CLC   0(4,3),0(2)
         LA    4,1(0,0)
         BH    *+12
         BL    *+6
         SLR   4,4
         LNR   4,4
         LTR   4,4
         BNE   @@L118
         LA    2,168(,13)
         ST    2,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXTRK)
         BALR  14,15
@@L167   EQU   *
         L     12,0(,10)
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
         L     2,32(7)
         A     2,=F'4'
         B     @@L159
@@L118   EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'126'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L121
         MVI   0(15),0
@@L121   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         MVC   92(4,13),32(7)
         LA    1,88(,13)
         L     15,=V(@@TXBLK)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
         LTR   3,3
         BE    @@L117
         LR    2,3
         A     2,=F'1'
@@L159   EQU   *
         L     12,0(,10)
         ST    2,32(7)
@@L117   EQU   *
         L     12,0(,10)
         L     4,32(7)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L125
         N     2,=XL4'000000FF'
         L     3,=V(@@ISBUF)
         L     3,0(3)
@@L160   EQU   *
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BNE   @@L125
         A     4,=F'1'
         ST    4,32(7)
         IC    2,0(4)
         CLM   2,1,=XL1'00'
         BE    @@L125
         N     2,=XL4'000000FF'
         B     @@L160
@@L125   EQU   *
         L     12,0(,10)
         LA    2,168(,13)
         ST    2,88(13)
         MVC   92(4,13),32(7)
         LA    1,88(,13)
         L     15,=V(@@TXSPAC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L114   EQU   *
         L     12,0(,10)
         L     3,36(7)
         LTR   3,3
         L     14,=A(@@L128)
         BER   14
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXUNIT)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L128   EQU   *
         L     12,0(,10)
         L     3,40(7)
         LTR   3,3
         L     14,=A(@@L130)
         BER   14
         LA    2,168(,13)
         ST    2,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXVOLS)
         BALR  14,15
         LR    6,15
         LTR   15,15
         L     14,=A(@@L5)
         BNER  14
@@L130   EQU   *
         L     12,0(,10)
         B     @@PGE0
         DS    0F
         LTORG
         DS    0F
@@PGE0   EQU   *
         DROP  12
         BASR  12,0
         USING *,12
@@PG1    EQU   *
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         LR    2,15
         BCTR  2,0
         L     4,168(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   144(13),20
         MVI   145(13),1
         MVI   146(13),64
         L     2,36(7)
         LTR   2,2
         BNE   @@L134
         L     2,40(7)
         LTR   2,2
         BE    @@L133
@@L134   EQU   *
         L     12,4(,10)
         L     2,44(7)
         LTR   2,2
         BNE   @@L133
         MVI   146(13),96
@@L133   EQU   *
         L     12,4(,10)
         MVC   152(4,13),168(13)
         LA    2,144(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L5
         L     3,0(11)
         LTR   3,3
         BE    @@L5
         L     2,168(13)
         L     2,0(2)
         MVC   0(8,3),6(2)
         STC   15,8(3)
@@L5     EQU   *
         L     12,4(,10)
         LTR   9,9
         BE    @@L137
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L137   EQU   *
         L     12,4(,10)
         L     2,172(13)
         MVC   276(4,2),176(13)
         L     2,168(13)
         LTR   2,2
         BE    @@L138
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L138   EQU   *
         L     12,4(,10)
         LR    15,6
@@L1     EQU   *
         L     12,4(,10)
* Function __dsalc epilogue
         PDPEPIL
* Function __dsalc literal pool
         DS    0F
         LTORG
* Function __dsalc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DC    A(@@PG1)
         END
