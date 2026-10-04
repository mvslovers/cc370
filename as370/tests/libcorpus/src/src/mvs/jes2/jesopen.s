         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesopen prologue
JESOPEN  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesopen code
         MVC   96(4,13),=F'0'
         MVC   88(4,13),=A(@@F6)
         LA    2,96(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         L     15,96(13)
* Function jesopen epilogue
         PDPEPIL
* Function jesopen literal pool
         DS    0F
         LTORG
* Function jesopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'try_jesopen'
@@LC0    EQU   *
         DC    C'Unable to allocate storage for JES handle'
         DC    X'0'
@@LC1    EQU   *
         DC    C'DD:HASPCKPT'
         DC    X'0'
@@LC2    EQU   *
         DC    C'Unable to open checkpoint dataset DD:HASPCKPT'
         DC    X'0'
@@LC3    EQU   *
         DC    C'DD:HASPACE1'
         DC    X'0'
@@LC4    EQU   *
         DC    C'Unable to open spool dataset DD:HASPACE1'
         DC    X'0'
@@LC5    EQU   *
         DC    C'Unable to add spool handle to JES handle'
         DC    X'0'
         DS    0F
* Function try_jesopen,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function try_jesopen code
         MVC   96(4,13),=F'0'
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'32'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,96(13)
         LTR   15,15
         BNE   @@L3
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L4
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(@@CPOPEN)
         BALR  14,15
         LTR   15,15
         BNE   @@L5
         MVC   88(4,13),=A(@@LC2)
         B     @@L9
@@L5     EQU   *
         L     12,0(,10)
         L     2,96(13)
         ST    15,8(2)
         MVC   88(4,13),=A(@@LC3)
         LA    1,88(,13)
         L     15,=V(@@JSOPEN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L6
         MVC   88(4,13),=A(@@LC4)
@@L9     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L8
@@L6     EQU   *
         L     12,0(,10)
         L     2,96(13)
         A     2,=F'12'
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@JSCLOS)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(JESCLOSE)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         L     2,0(11)
         MVC   0(4,2),96(13)
* Function try_jesopen epilogue
         PDPEPIL
* Function try_jesopen literal pool
         DS    0F
         LTORG
* Function try_jesopen page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
