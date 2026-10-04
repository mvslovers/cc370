         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'tzset'
         DC    X'0'
@@LC0    EQU   *
         DC    C'tz'
         DC    X'0'
@@LC1    EQU   *
         DC    C'TZ'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s: Invalid time zone format in TZ variable "%s"'
         DC    X'0'
@@LC3    EQU   *
         DC    C'%s: Expected format is TZ=[-]HH[:MM][:SS]'
         DC    X'0'
@@LC4    EQU   *
         DC    C'%s: Defaulting to time zone offset calculated fr'
         DC    C'om CVTTZ'
         DC    X'0'
         DS    0F
* X-func tzset prologue
TZSET    PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function tzset code
         SLR   6,6
         SLR   7,7
         LR    8,6
         LR    9,7
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
         LTR   15,15
         BNE   @@L2
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(GETENV)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LTR   15,15
         BE    @@L3
         LR    4,15
         SLR   5,5
         CLI   0(15),96
         BNE   @@L18
@@L6     EQU   *
         LA    5,1(0,0)
         AR    4,5
         CLI   0(4),96
         BE    @@L6
@@L18    EQU   *
         L     12,0(,10)
         SLR   2,2
         IC    2,0(4)
         L     3,=V(@@ISBUF)
         L     3,0(3)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'8'
         LTR   2,2
         BE    @@L7
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         LR    3,15
         MH    3,=H'3600'
         ST    4,88(13)
         MVC   92(4,13),=F'122'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L8
         A     4,=F'1'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         LR    2,15
         SLL   2,4
         SR    2,15
         SLL   2,2
         AR    3,2
         ST    4,88(13)
         MVC   92(4,13),=F'122'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    4,15
@@L8     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L9
         A     4,=F'1'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(ATOI)
         BALR  14,15
         AR    3,15
@@L9     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L11
         LCR   3,3
         B     @@L11
@@L7     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@V1)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC4)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LA    2,16(0,0)
         L     2,0(2)
         L     2,304(2)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         MD    2,=D'1.04857650000000002243894E+0'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     3,84(,13)
         LTR   3,3
         BNL   @@L12
         LCR   6,3
         SRDA  6,32
         LA    2,10(0,0)
         DR    6,2
         LR    2,6
         LTR   2,2
         BE    @@L11
         AR    3,2
         A     3,=F'-10'
         B     @@L11
@@L12    EQU   *
         L     12,0(,10)
         LTR   3,3
         BNH   @@L11
         LR    8,3
         SRDA  8,32
         LA    2,10(0,0)
         DR    8,2
         LR    2,8
         LTR   2,2
         BE    @@L11
         SR    3,2
         A     3,=F'10'
@@L11    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@TZSET)
         BALR  14,15
* Function tzset epilogue
         PDPEPIL
* Function tzset literal pool
         DS    0F
         LTORG
* Function tzset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
