         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'wto_traceback'
* Program text area
         DS    0F
* X-func *@@WTOTB prologue
@@WTOTB  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@WTOTB code
         MVC   88(4,13),=A(@@F6)
         MVC   92(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
* Function *@@WTOTB epilogue
         PDPEPIL
* Function *@@WTOTB literal pool
         DS    0F
         LTORG
* Function *@@WTOTB page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'try_traceback'
@@LC0    EQU   *
         DC    C'Save area trace back'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%08X (unknown)'
         DC    X'0'
@@LC2    EQU   *
         DC    C'  "%s" ep=%06X frame=%u bytes'
         DC    X'0'
@@LC3    EQU   *
         DC    C'    returns to=%06X "%s" ep=%06X+%X'
         DC    X'0'
         DS    0F
* Function try_traceback,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=664,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function try_traceback code
         L     8,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         ST    15,644(13)
         LTR   8,8
         BNE   @@L3
         ST     13,624(13)        return save area address
         L     3,624(13)
         L     8,4(3)
         LR    2,8
         LTR   8,8
         BNE   @@L7
         ST    3,628(13)
         LR    2,3
@@L7     EQU   *
         L     12,0(,10)
         L     8,4(2)
         LR    2,8
         LTR   8,8
         BNE   @@L10
         ST    3,632(13)
         LR    2,3
@@L10    EQU   *
         L     12,0(,10)
         L     8,4(2)
         LR    2,8
         LTR   8,8
         BNE   @@L13
         ST    3,636(13)
         LR    2,3
@@L13    EQU   *
         L     12,0(,10)
         L     8,4(2)
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   656(4,13),=F'0'
         MVC   648(4,13),4(8)
         L     2,644(13)
         CL    8,12(2)
         BE    @@L17
@@L28    EQU   *
         LR    2,8
         LTR   8,8
         BNE   @@L19
         ST     13,640(13)        return save area address
         L     2,640(13)
@@L19    EQU   *
         L     12,0(,10)
         MVC   652(4,13),8(2)
         L     3,648(13)
         MVC   660(4,13),16(3)
         MVI   368(13),0
         L     4,660(13)
         CLI   0(4),71
         BNE   @@L22
         CLI   1(4),240
         BNE   @@L22
         LR    3,4
         A     3,=F'4'
         SLR   2,2
         IC    2,0(3)
         LA    5,368(,13)
         LR    6,5
         LR    7,2
         A     4,=F'5'
         LR    5,2
         MVCL  6,4
         SLR   2,2
         IC    2,0(3)
         SLR   3,3
         STC   3,368(2,13)
         B     @@L24
@@L22    EQU   *
         L     12,0(,10)
         LA    4,368(,13)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC1)
         MVC   96(4,13),660(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L24    EQU   *
         L     12,0(,10)
         L     9,16(8)
         MVI   112(13),0
         CLI   0(9),71
         BNE   @@L25
         CLI   1(9),240
         BNE   @@L25
         LR    3,9
         A     3,=F'4'
         SLR   2,2
         IC    2,0(3)
         LA    5,112(,13)
         LR    6,5
         LR    7,2
         LR    4,9
         A     4,=F'5'
         LR    5,2
         MVCL  6,4
         SLR   2,2
         IC    2,0(3)
         SLR   3,3
         STC   3,112(2,13)
         B     @@L27
@@L25    EQU   *
         L     12,0(,10)
         LA    4,112(,13)
         ST    4,88(13)
         MVC   92(4,13),=A(@@LC1)
         ST    9,96(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L27    EQU   *
         L     12,0(,10)
         L     5,652(13)
         L     2,76(5)
         SR    2,5
         L     3,12(8)
         N     3,=F'268435455'
         LR    4,3
         L     5,648(13)
         S     4,16(5)
         MVC   88(4,13),=A(@@LC2)
         LA    5,112(,13)
         ST    5,92(13)
         ST    9,96(13)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC3)
         ST    3,92(13)
         LA    2,368(,13)
         ST    2,96(13)
         MVC   100(4,13),660(13)
         ST    4,104(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         L     3,656(13)
         A     3,=F'1'
         ST    3,656(13)
         L     8,648(13)
         MVC   648(4,13),4(8)
         LA    4,255(0,0)
         CR    3,4
         BH    @@L17
         L     5,644(13)
         CL    8,12(5)
         BNE   @@L28
@@L17    EQU   *
         L     12,0(,10)
* Function try_traceback epilogue
         PDPEPIL
* Function try_traceback literal pool
         DS    0F
         LTORG
* Function try_traceback page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
