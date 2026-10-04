         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'365'
         DC    F'366'
         
&FUNC    SETC 'seconds_between_years'
         DS    0F
* X-func *TM64SBY prologue
TM64SBY  PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64SBY code
         SLR   4,4
         SLR   5,5
         LR    6,4
         LR    7,5
         ST    4,120(13)
         ST    5,4+120(13)
         ST    4,128(13)
         ST    5,4+128(13)
         ST    4,136(13)
         ST    5,4+136(13)
         ST    0,112(13)
         L     3,0(11)
         L     9,4(11)
         MVC   116(4,13),=F'1'
         CR    3,9
         BH    @@L3
         MVC   116(4,13),=F'-1'
@@L3     EQU   *
         L     12,0(,10)
         LA    8,104(,13)
         ST    8,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LA    2,2400(0,0)
         CR    3,2
         BNH   @@L4
         LR    4,3
         A     4,=F'-2400'
         SRDA  4,32
         LA    6,400(0,0)
         DR    4,6
         LR    2,5
         MH    2,=H'400'
         SR    3,2
         ST    8,88(13)
         MVC   92(8,13),=XL8'00000002F0605980'
         LA    1,88(,13)
         L     15,=V(@@64FU64)
         BALR  14,15
         ST    8,88(13)
         ST    5,92(13)
         B     @@L15
@@L4     EQU   *
         L     12,0(,10)
         LA    2,1599(0,0)
         CR    3,2
         BH    @@L5
         LR    6,3
         A     6,=F'-1600'
         SRDA  6,32
         LA    2,400(0,0)
         DR    6,2
         LR    2,7
         MH    2,=H'400'
         AR    3,2
         ST    8,88(13)
         MVC   92(8,13),=XL8'00000002F0605980'
         LA    1,88(,13)
         L     15,=V(@@64FU64)
         BALR  14,15
         ST    8,88(13)
         ST    7,92(13)
@@L15    EQU   *
         L     12,0(,10)
         ST    8,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MI32)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         CLR   3,9
         BE    @@L14
         LA    5,104(,13)
         ST    5,88(13)
         ST    9,120(13)
         L     6,120(13)
         L     7,4+120(13)
         SRDA  6,32
         LA    2,400(0,0)
         DR    6,2
         ST    6,120(13)
         ST    7,4+120(13)
         LTR   6,6
         BE    @@L11
         LR    2,9
         N     2,=F'3'
         LTR   2,2
         BNE   @@L9
         ST    9,128(13)
         L     6,128(13)
         L     7,4+128(13)
         SRDA  6,32
         LA    2,100(0,0)
         DR    6,2
         ST    6,128(13)
         ST    7,4+128(13)
         LTR   6,6
         BE    @@L9
@@L11    EQU   *
         L     12,0(,10)
         LA    4,4(0,0)
         B     @@L10
@@L9     EQU   *
         L     12,0(,10)
         SLR   4,4
@@L10    EQU   *
         L     12,0(,10)
         L     6,=F'86400'
         ST    6,140(13)
         L     2,=A(@V1)
         L     6,136(13)
         L     7,4+136(13)
         L     2,0(4,2)
         MR    6,2
         ST    6,136(13)
         ST    7,4+136(13)
         ST    7,92(13)
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         A     9,116(13)
         B     @@L5
@@L14    EQU   *
         L     12,0(,10)
         L     7,112(13)
         MVC   0(8,7),104(13)
         LR    15,7
* Function *TM64SBY epilogue
         PDPEPIL
* Function *TM64SBY literal pool
         DS    0F
         LTORG
* Function *TM64SBY page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
