         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'mktime64'
* Program text area
         DS    0F
* X-func *TM64MKT prologue
TM64MKT  PDPPRLG CINDEX=0,FRAME=200,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64MKT code
         LR    6,0
         L     5,0(11)
         L     2,20(5)
         LR    4,2
         A     4,=F'1900'
         LA    3,192(,13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@64INIT)
         BALR  14,15
         A     2,=F'-70'
         L     7,=F'8029'
         CLR   2,7
         BNH   @@L2
         ST    3,88(13)
         MVC   92(4,13),=F'1'
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SI32)
         BALR  14,15
         B     @@L3
@@L2     EQU   *
         L     12,0(,10)
         LA    7,67(0,0)
         CLR   2,7
         BH    @@L4
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         B     @@L3
@@L4     EQU   *
         L     12,0(,10)
         MVC   144(36,13),0(5)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(TM64SYR)
         BALR  14,15
         A     15,=F'-1900'
         ST    15,164(13)
         MVC   104(36,13),144(13)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(MKTIME)
         BALR  14,15
         ST    3,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@64FU32)
         BALR  14,15
         ST    4,88(13)
         L     2,124(13)
         A     2,=F'1900'
         ST    2,92(13)
         LA    0,184(,13)
         LA    1,88(,13)
         L     15,=V(TM64SBY)
         BALR  14,15
         ST    3,88(13)
         MVC   92(8,13),184(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@64AU64)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(TM64GMT)
         BALR  14,15
         MVC   0(36,5),0(15)
@@L3     EQU   *
         L     12,0(,10)
         MVC   0(8,6),192(13)
         LR    15,6
* Function *TM64MKT epilogue
         PDPEPIL
* Function *TM64MKT literal pool
         DS    0F
         LTORG
* Function *TM64MKT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
