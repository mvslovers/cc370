         COPY  PDPTOP
         CSECT
         
* safe_years_high
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'2016'
         DC    F'2017'
         DC    F'2018'
         DC    F'2019'
         DC    F'2020'
         DC    F'2021'
         DC    F'2022'
         DC    F'2023'
         DC    F'2024'
         DC    F'2025'
         DC    F'2026'
         DC    F'2027'
         DC    F'2028'
         DC    F'2029'
         DC    F'2030'
         DC    F'2031'
         DC    F'2032'
         DC    F'2033'
         DC    F'2034'
         DC    F'2035'
         DC    F'2036'
         DC    F'2037'
         DC    F'2010'
         DC    F'2011'
         DC    F'2012'
         DC    F'2013'
         DC    F'2014'
         DC    F'2015'
         
* safe_years_low
         DS    0F
@V2      EQU   *
         DC    F'1996'
         DC    F'1997'
         DC    F'1998'
         DC    F'1971'
         DC    F'1972'
         DC    F'1973'
         DC    F'1974'
         DC    F'1975'
         DC    F'1976'
         DC    F'1977'
         DC    F'1978'
         DC    F'1979'
         DC    F'1980'
         DC    F'1981'
         DC    F'1982'
         DC    F'1983'
         DC    F'1984'
         DC    F'1985'
         DC    F'1986'
         DC    F'1987'
         DC    F'1988'
         DC    F'1989'
         DC    F'1990'
         DC    F'1991'
         DC    F'1992'
         DC    F'1993'
         DC    F'1994'
         DC    F'1995'
         
&FUNC    SETC 'cycle_offset'
         DS    0F
* Function cycle_offset,F2 prologue
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
* Function cycle_offset code
         SLR   4,4
         SLR   5,5
         LR    2,4
         LR    3,5
         L     6,0(11)
         LR    15,6
         A     15,=F'-2000'
         LA    7,2000(0,0)
         CR    6,7
         BNH   @@L2
         BCTR  15,0
@@L2     EQU   *
         L     12,0(,10)
         LR    4,15
         SRDA  4,32
         LA    6,100(0,0)
         DR    4,6
         LR    2,15
         SRDA  2,32
         LA    7,400(0,0)
         DR    2,7
         LR    15,5
         SR    15,3
         SLL   15,4
* Function cycle_offset epilogue
         PDPEPIL
* Function cycle_offset literal pool
         DS    0F
         LTORG
* Function cycle_offset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'safe_year'
@@LC0    EQU   *
         DC    C'year_cycle >= 0'
         DC    X'0'
@@LC1    EQU   *
         DC    C'src/ext/time64/tm64syr.c'
         DC    X'0'
@@LC2    EQU   *
         DC    C'year_cycle < SOLAR_CYCLE_LENGTH'
         DC    X'0'
@@LC3    EQU   *
         DC    C'0'
         DC    X'0'
@@LC4    EQU   *
         DC    C'safe_year <= MAX_SAFE_YEAR '
         DC    X'50'
         DC    X'50'
         DC    C' safe_year >= MIN_SAFE_YEAR'
         DC    X'0'
         DS    0F
* X-func *TM64SYR prologue
TM64SYR  PDPPRLG CINDEX=1,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function *TM64SYR code
         SLR   4,4
         SLR   5,5
         LR    6,4
         LR    7,5
         LR    8,4
         LR    9,5
         ST    4,112(13)
         ST    5,4+112(13)
         ST    4,120(13)
         ST    5,4+120(13)
         MVC   104(4,13),0(11)
         MVC   108(4,13),=F'0'
         L     2,104(13)
         A     2,=F'-1970'
         L     15,104(13)
         LA    3,67(0,0)
         CLR   2,3
         BNH   @@L3
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         L     3,104(13)
         AR    3,15
         L     2,104(13)
         LA    15,1969(0,0)
         CR    2,15
         BH    @@L5
         A     3,=F'-8'
@@L5     EQU   *
         L     12,0(,10)
         L     4,104(13)
         SRDA  4,32
         LA    15,100(0,0)
         DR    4,15
         LTR   4,4
         BNE   @@L6
         L     6,104(13)
         SRDA  6,32
         LA    2,400(0,0)
         DR    6,2
         LTR   6,6
         BE    @@L6
         A     3,=F'11'
@@L6     EQU   *
         L     12,0(,10)
         L     2,104(13)
         BCTR  2,0
         LR    8,2
         SRDA  8,32
         LA    4,100(0,0)
         DR    8,4
         LTR   8,8
         BNE   @@L7
         ST    2,112(13)
         L     4,112(13)
         L     5,4+112(13)
         SRDA  4,32
         ST    4,112(13)
         ST    5,4+112(13)
         LA    15,400(0,0)
         DR    4,15
         LTR   4,4
         BE    @@L7
         A     3,=F'17'
@@L7     EQU   *
         L     12,0(,10)
         ST    3,120(13)
         L     2,120(13)
         L     3,4+120(13)
         SRDA  2,32
         ST    2,120(13)
         ST    3,4+120(13)
         LA    4,28(0,0)
         DR    2,4
         LR    3,2
         LTR   2,2
         BNL   @@L8
         AR    3,4
@@L8     EQU   *
         L     12,0(,10)
         LTR   3,3
         BNL   @@L10
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),=F'128'
         LA    1,88(,13)
         L     15,=V(@@ASSERT)
         BALR  14,15
@@L10    EQU   *
         L     12,0(,10)
         LA    5,27(0,0)
         CR    3,5
         BNH   @@L12
         MVC   88(4,13),=A(@@LC2)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),=F'129'
         LA    1,88(,13)
         L     15,=V(@@ASSERT)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         L     2,104(13)
         LA    15,1969(0,0)
         CR    2,15
         BH    @@L13
         SLL   3,2
         L     2,=A(@V2)
         B     @@L19
@@L13    EQU   *
         L     12,0(,10)
         L     5,104(13)
         LA    4,2037(0,0)
         CR    5,4
         BNH   @@L15
         SLL   3,2
         L     2,=A(@V1)
@@L19    EQU   *
         L     12,0(,10)
         L     3,0(3,2)
         ST    3,108(13)
         B     @@L14
@@L15    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC3)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),=F'133'
         LA    1,88(,13)
         L     15,=V(@@ASSERT)
         BALR  14,15
@@L14    EQU   *
         L     12,0(,10)
         L     2,108(13)
         A     2,=F'-1970'
         LA    15,67(0,0)
         CLR   2,15
         BNH   @@L18
         MVC   88(4,13),=A(@@LC4)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),=F'135'
         LA    1,88(,13)
         L     15,=V(@@ASSERT)
         BALR  14,15
@@L18    EQU   *
         L     12,0(,10)
         L     15,108(13)
@@L3     EQU   *
         L     12,0(,10)
* Function *TM64SYR epilogue
         PDPEPIL
* Function *TM64SYR literal pool
         DS    0F
         LTORG
* Function *TM64SYR page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
