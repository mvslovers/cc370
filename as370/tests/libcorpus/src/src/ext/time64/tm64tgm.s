         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'365'
         DC    F'366'
         
&FUNC    SETC 'timegm64'
         DS    0F
* X-func *TM64TGM prologue
TM64TGM  PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64TGM code
         SLR   8,8
         SLR   9,9
         LR    6,8
         LR    7,9
         ST    8,128(13)
         ST    9,4+128(13)
         ST    8,136(13)
         ST    9,4+136(13)
         ST    0,120(13)
         L     2,0(11)
         L     4,20(2)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LA    3,112(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         LA    2,470(0,0)
         CR    4,2
         BNH   @@L18
@@L4     EQU   *
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'146097'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AU32)
         BALR  14,15
         A     4,=F'-400'
         LA    3,470(0,0)
         CR    4,3
         BH    @@L4
@@L18    EQU   *
         L     12,0(,10)
         LA    2,70(0,0)
         CR    4,2
         BNH   @@L5
         LR    5,2
@@L21    EQU   *
         CR    5,4
         BNL   @@L12
         LA    15,104(,13)
         ST    15,88(13)
         LR    3,5
         A     3,=F'1900'
         LR    8,3
         SRDA  8,32
         LA    2,400(0,0)
         DR    8,2
         LTR   8,8
         BE    @@L10
         LR    2,3
         N     2,=F'3'
         LTR   2,2
         BNE   @@L8
         LR    6,3
         SRDA  6,32
         LA    3,100(0,0)
         DR    6,3
         LTR   6,6
         BE    @@L8
@@L10    EQU   *
         L     12,0(,10)
         LA    3,4(0,0)
         B     @@L9
@@L8     EQU   *
         L     12,0(,10)
         SLR   3,3
@@L9     EQU   *
         L     12,0(,10)
         L     2,=A(@V1)
         L     2,0(3,2)
         ST    2,92(13)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         A     5,=F'1'
         B     @@L21
@@L5     EQU   *
         L     12,0(,10)
         LA    6,69(0,0)
         CR    4,6
         BH    @@L12
         DS    0H  year < 70 - indicate failure
         LA    7,112(,13)
         ST    7,88(13)
         MVC   92(4,13),=F'1'
         ST    7,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SI32)
         BALR  14,15
         L     2,120(13)
         MVC   0(8,2),112(13)
         B     @@L1
@@L12    EQU   *
         L     12,0(,10)
         SLR   5,5
         LR    3,4
         A     3,=F'1900'
         ST    3,128(13)
         L     6,128(13)
         L     7,4+128(13)
         SRDA  6,32
         ST    6,128(13)
         ST    7,4+128(13)
         LA    2,400(0,0)
         DR    6,2
         LTR   6,6
         BE    @@L15
         LR    2,3
         N     2,=F'3'
         LTR   2,2
         BNE   @@L14
         ST    3,136(13)
         L     6,136(13)
         L     7,4+136(13)
         SRDA  6,32
         ST    6,136(13)
         ST    7,4+136(13)
         LA    2,100(0,0)
         DR    6,2
         LTR   6,6
         BE    @@L14
@@L15    EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
@@L14    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         L     3,0(11)
         MVC   92(4,13),16(3)
         LA    1,88(,13)
         L     15,=V(TM64JDBM)
         BALR  14,15
         LA    3,104(,13)
         ST    3,88(13)
         ST    15,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         ST    3,88(13)
         L     4,0(11)
         L     2,12(4)
         BCTR  2,0
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         ST    3,88(13)
         MVC   92(4,13),=F'86400'
         LA    6,112(,13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@64MI32)
         BALR  14,15
         ST    6,88(13)
         L     2,8(4)
         MH    2,=H'3600'
         ST    2,92(13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         ST    6,88(13)
         L     2,4(4)
         SLL   2,4
         S     2,4(4)
         SLL   2,2
         ST    2,92(13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
         ST    6,88(13)
         MVC   92(4,13),0(4)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@64AI32)
         BALR  14,15
@@L16    EQU   *
         L     7,120(13)
         MVC   0(8,7),112(13)
@@L1     EQU   *
         L     12,0(,10)
         L     15,120(13)
* Function *TM64TGM epilogue
         PDPEPIL
* Function *TM64TGM literal pool
         DS    0F
         LTORG
* Function *TM64TGM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
