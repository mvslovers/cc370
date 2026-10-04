         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'localtime64_r'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s: NULL time pointer parameter 1'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s: NULL local_tm pointer parameter 2'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s: gmtime64_r failure for time value 0x%016llX '
         DC    C'(%llu)'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s: localtime_r failure for time value 0x%08X (%'
         DC    C'u)'
         DC    X'0'
         DS    0F
* X-func *TM64LTMR prologue
TM64LTMR PDPPRLG CINDEX=0,FRAME=208,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64LTMR code
         SLR   4,4
         SLR   5,5
         LR    6,4
         LR    7,5
         L     3,0(11)
         L     8,4(11)
         LTR   3,3
         BNE   @@L2
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LR    15,3
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LTR   8,8
         BNE   @@L3
         MVC   88(4,13),=A(@@LC1)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L9
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    9,152(,13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(TM64GMTR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L4
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@V1)
         MVC   96(8,13),0(3)
         MVC   104(8,13),0(3)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L12
@@L4     EQU   *
         L     12,0(,10)
         L     3,172(13)
         LR    2,3
         A     2,=F'-70'
         LA    15,67(0,0)
         CLR   2,15
         BNH   @@L5
         A     3,=F'1900'
         ST    3,88(13)
         A     3,=F'-1900'
         LA    1,88(,13)
         L     15,=V(TM64SYR)
         BALR  14,15
         A     15,=F'-1900'
         ST    15,172(13)
@@L5     EQU   *
         L     12,0(,10)
         ST    9,88(13)
         LA    0,192(,13)
         LR    2,0
         LA    1,88(,13)
         L     15,=V(TM64TGM)
         BALR  14,15
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@64TU32)
         BALR  14,15
         ST    15,200(13)
         LA    2,200(,13)
         ST    2,88(13)
         LA    2,112(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(LOCALTMR)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BNE   @@L6
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@V1)
         MVC   96(4,13),200(13)
         MVC   100(4,13),200(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         LR    15,2
         B     @@L1
@@L6     EQU   *
         L     12,0(,10)
         MVC   0(36,8),112(13)
         ST    3,20(8)
         L     2,16(8)
         S     2,168(13)
         LA    9,11(0,0)
         CLR   2,9
         BNE   @@L7
         BCTR  3,0
         B     @@L11
@@L7     EQU   *
         L     12,0(,10)
         L     15,=F'-11'
         CLR   2,15
         BNE   @@L8
         A     3,=F'1'
@@L11    EQU   *
         L     12,0(,10)
         ST    3,20(8)
@@L8     EQU   *
         L     12,0(,10)
         L     3,20(8)
         A     3,=F'1900'
         LR    4,3
         SRDA  4,32
         LA    2,400(0,0)
         DR    4,2
         LTR   4,4
         BE    @@L9
         LR    2,3
         N     2,=F'3'
         LTR   2,2
         BNE   @@L10
         LR    6,3
         SRDA  6,32
         LA    3,100(0,0)
         DR    6,3
         LTR   6,6
         BNE   @@L9
@@L10    EQU   *
         L     12,0(,10)
         L     2,28(8)
         LA    9,365(0,0)
         CLR   2,9
         BNE   @@L9
         MVC   28(4,8),=F'364'
@@L9     EQU   *
         L     12,0(,10)
         LR    15,8
@@L1     EQU   *
         L     12,0(,10)
* Function *TM64LTMR epilogue
         PDPEPIL
* Function *TM64LTMR literal pool
         DS    0F
         LTORG
* Function *TM64LTMR page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
