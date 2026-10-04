         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'Sun'
         DC    C'Mon'
         DC    C'Tue'
         DC    C'Wed'
         DC    C'Thu'
         DC    C'Fri'
         DC    C'Sat'
@V2      EQU   *
         DC    C'Jan'
         DC    C'Feb'
         DC    C'Mar'
         DC    C'Apr'
         DC    C'May'
         DC    C'Jun'
         DC    C'Jul'
         DC    C'Aug'
         DC    C'Sep'
         DC    C'Oct'
         DC    C'Nov'
         DC    C'Dec'
         
&FUNC    SETC 'valid_tm_wday'
         DS    0F
* Function valid_tm_wday,F2 prologue
@@F2     PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function valid_tm_wday code
         L     2,0(11)
         L     2,24(2)
         LA    15,1(0,0)
         LA    3,6(0,0)
         CLR   2,3
         BNH   @@L1
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function valid_tm_wday epilogue
         PDPEPIL
* Function valid_tm_wday literal pool
         DS    0F
         LTORG
* Function valid_tm_wday page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'valid_tm_mon'
         DS    0F
* Function valid_tm_mon,F3 prologue
@@F3     PDPPRLG CINDEX=1,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function valid_tm_mon code
         L     2,0(11)
         L     2,16(2)
         LA    15,1(0,0)
         LA    3,11(0,0)
         CLR   2,3
         BNH   @@L4
         SLR   15,15
@@L4     EQU   *
         L     12,0(,10)
* Function valid_tm_mon epilogue
         PDPEPIL
* Function valid_tm_mon literal pool
         DS    0F
         LTORG
* Function valid_tm_mon page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'asctime64_r'
@@LC0    EQU   *
         DC    C'%.3s %.3s%3d %.2d:%.2d:%.2d %d'
         DC    X'15'
         DC    X'0'
         DS    0F
* X-func *TM64ASCR prologue
TM64ASCR PDPPRLG CINDEX=2,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function *TM64ASCR code
         L     3,0(11)
         L     5,4(11)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L9
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=A(@@F3)
         BALR  14,15
         LTR   15,15
         BNE   @@L8
@@L9     EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         L     4,20(3)
         A     4,=F'1900'
         SLR   15,15
         L     2,=F'9999'
         CR    4,2
         BH    @@L7
         LTR   5,5
         BE    @@L11
         ST    5,88(13)
         MVC   92(4,13),=F'26'
         MVC   96(4,13),=A(@@LC0)
         L     2,24(3)
         SLL   2,1
         A     2,24(3)
         A     2,=A(@V1)
         ST    2,100(13)
         L     2,16(3)
         SLL   2,1
         A     2,16(3)
         A     2,=A(@V2)
         ST    2,104(13)
         MVC   108(4,13),12(3)
         MVC   112(4,13),8(3)
         MVC   116(4,13),4(3)
         MVC   120(4,13),0(3)
         ST    4,124(13)
         LA    1,88(,13)
         L     15,=V(SNPRINTF)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         LR    15,5
@@L7     EQU   *
         L     12,0(,10)
* Function *TM64ASCR epilogue
         PDPEPIL
* Function *TM64ASCR literal pool
         DS    0F
         LTORG
* Function *TM64ASCR page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         END
