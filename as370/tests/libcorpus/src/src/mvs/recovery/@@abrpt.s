         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'get_offset'
* Program text area
@@LC0    EQU   *
         DC    C'epname %-*.*s offset %08X'
         DC    X'0'
         DS    0F
* Function get_offset,F6 prologue
@@F6     PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function get_offset code
         L     2,0(11)
         L     5,4(11)
         L     3,108(2)
         L     2,76(2)
         MVI   0(5),0
         L     4,=F'8191'
         CLR   2,4
         BNH   @@L1
         L     2,4(2)
         L     15,16(2)
         LR    4,3
         SR    4,15
         CLR   15,3
         BH    @@L1
         L     2,0(15)
         SRL   2,8
         L     3,=F'4714736'
         CLR   2,3
         BNE   @@L1
         IC    2,4(15)
         CLM   2,1,3(15)
         BH    @@L1
         N     2,=XL4'000000FF'
         LA    3,40(0,0)
         CLR   2,3
         BNH   @@L7
         LR    2,3
@@L7     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    2,96(13)
         ST    2,100(13)
         A     15,=F'5'
         ST    15,104(13)
         ST    4,108(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L3     EQU   *
@@L1     EQU   *
         L     12,0(,10)
* Function get_offset epilogue
         PDPEPIL
* Function get_offset literal pool
         DS    0F
         LTORG
* Function get_offset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'get_addr'
@@LC1    EQU   *
         DC    C'........ ........ ........ ........ *...........'
         DC    C'.....*'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%08X'
         DC    X'0'
         DS    0F
* Function get_addr,F7 prologue
@@F7     PDPPRLG CINDEX=1,FRAME=120,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function get_addr code
         L     3,0(11)
         L     2,=A(@@LC1)
         L     4,4(11)
         MVC   0(55,4),0(2)
         LR    2,3
         A     2,=F'-8192'
         L     6,=F'16703487'
         CLR   2,6
         BH    @@L8
         SLR   7,7
         LA    9,37(0,0)
         LR    4,3
         LR    5,3
         LR    8,7
@@L19    EQU   *
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC2)
         MVC   96(4,13),0(4)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         L     2,104(13)
         L     3,4+104(13)
         L     6,4(11)
         ST    2,0(7,6)
         ST    3,4+0(7,6)
         LA    6,3(0,0)
@@L18    EQU   *
         IC    15,0(5)
         LR    2,15
         N     2,=XL4'000000FF'
         L     3,=V(@@ISBUF)
         L     3,0(3)
         AR    2,2
         LH    2,0(2,3)
         N     2,=F'16'
         LTR   2,2
         BE    @@L16
         L     2,4(11)
         STC   15,0(9,2)
@@L16    EQU   *
         L     12,0(,10)
         BCTR  6,0
         A     5,=F'1'
         A     9,=F'1'
         LTR   6,6
         BNL   @@L18
         A     8,=F'1'
         A     4,=F'4'
         A     7,=F'9'
         LA    3,3(0,0)
         CR    8,3
         BNH   @@L19
@@L10    EQU   *
@@L8     EQU   *
         L     12,0(,10)
* Function get_addr epilogue
         PDPEPIL
* Function get_addr literal pool
         DS    0F
         LTORG
* Function get_addr page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'get_epname'
@@LC3    EQU   *
         DC    C'%-*.*s'
         DC    X'0'
         DS    0F
* Function get_epname,F8 prologue
@@F8     PDPPRLG CINDEX=2,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function get_epname code
         L     15,0(11)
         L     3,4(11)
         MVI   0(3),0
         L     2,0(15)
         SRL   2,8
         L     4,=F'4714736'
         CLR   2,4
         BNE   @@L23
         IC    2,4(15)
         CLM   2,1,3(15)
         BH    @@L23
         N     2,=XL4'000000FF'
         LA    4,40(0,0)
         CLR   2,4
         BNH   @@L27
         LR    2,4
@@L27    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC3)
         ST    2,96(13)
         ST    2,100(13)
         A     15,=F'5'
         ST    15,104(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L26    EQU   *
@@L23    EQU   *
         L     12,0(,10)
* Function get_epname epilogue
         PDPEPIL
* Function get_epname literal pool
         DS    0F
         LTORG
* Function get_epname page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC 'dump_regs'
@@LC4    EQU   *
         DC    C'R%02d:%08X:%s'
         DC    X'0'
         DS    0F
* Function dump_regs,F9 prologue
@@F9     PDPPRLG CINDEX=3,FRAME=184,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function dump_regs code
         SLR   4,4
         L     3,0(11)
         A     3,=F'24'
@@L32    EQU   *
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),0(3)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC4)
         ST    4,92(13)
         MVC   96(4,13),0(3)
         ST    2,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         A     4,=F'1'
         A     3,=F'4'
         LA    2,15(0,0)
         CR    4,2
         BNH   @@L32
         SLR   15,15
* Function dump_regs epilogue
         PDPEPIL
* Function dump_regs literal pool
         DS    0F
         LTORG
* Function dump_regs page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         
&FUNC    SETC 'get_sa_prev'
         DS    0F
* Function get_sa_prev,F10 prologue
@@F10    PDPPRLG CINDEX=4,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN4
         LTORG
@@FEN4   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG4    EQU   *
         LR    11,1
         L     10,=A(@@PGT4)
* Function get_sa_prev code
         L     2,0(11)
         L     15,4(2)
         LR    2,15
         A     2,=F'-8192'
         L     3,=F'16703487'
         CLR   2,3
         BH    @@L36
         L     2,4(11)
         ST    15,0(2)
@@L36    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function get_sa_prev epilogue
         PDPEPIL
* Function get_sa_prev literal pool
         DS    0F
         LTORG
* Function get_sa_prev page table
         DS    0F
@@PGT4   EQU   *
         DC    A(@@PG4)
         
&FUNC    SETC 'get_sa_next'
         DS    0F
* Function get_sa_next,F11 prologue
@@F11    PDPPRLG CINDEX=5,FRAME=88,BASER=12,ENTRY=NO
         B     @@FEN5
         LTORG
@@FEN5   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG5    EQU   *
         LR    11,1
         L     10,=A(@@PGT5)
* Function get_sa_next code
         L     2,0(11)
         L     15,8(2)
         LR    2,15
         A     2,=F'-8192'
         L     3,=F'16703487'
         CLR   2,3
         BH    @@L38
         L     2,4(11)
         ST    15,0(2)
@@L38    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function get_sa_next epilogue
         PDPEPIL
* Function get_sa_next literal pool
         DS    0F
         LTORG
* Function get_sa_next page table
         DS    0F
@@PGT5   EQU   *
         DC    A(@@PG5)
         
&FUNC    SETC 'dump_sa'
@@LC5    EQU   *
         DC    C'------------------------------------------------'
         DC    X'0'
@@LC6    EQU   *
         DC    C'%s'
         DC    X'0'
@@LC7    EQU   *
         DC    C'DSA:%08X:%s'
         DC    X'0'
@@LC8    EQU   *
         DC    C'R14:%08X:%s'
         DC    X'0'
@@LC9    EQU   *
         DC    C'R15:%08X:%s'
         DC    X'0'
@@LC10   EQU   *
         DC    C'R00:%08X:%s'
         DC    X'0'
@@LC11   EQU   *
         DC    C'R01:%08X:%s'
         DC    X'0'
@@LC12   EQU   *
         DC    C'Traceback interrupted, Forward from PPA %08X'
         DC    X'0'
         DS    0F
* Function dump_sa,F12 prologue
@@F12    PDPPRLG CINDEX=6,FRAME=192,BASER=12,ENTRY=NO
         B     @@FEN6
         LTORG
@@FEN6   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG6    EQU   *
         LR    11,1
         L     10,=A(@@PGT6)
* Function dump_sa code
         SLR   3,3
         L     2,540(3)
         L     2,112(2)
         N     2,=F'16777215'
         L     4,8(2)
         L     2,0(11)
         L     2,76(2)
         ST    3,184(13)
         MVC   88(4,13),=A(@@F10)
         ST    2,92(13)
         LA    5,184(,13)
@@L55    EQU   *
         ST    5,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         L     2,184(13)
         LTR   2,2
         BE    @@L53
         L     2,184(13)
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F8)
         MVC   92(4,13),16(2)
         LA    3,104(,13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         CLI   104(13),0
         BE    @@L43
         MVC   88(4,13),=A(@@LC6)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L43    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@F7)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC7)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),12(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC8)
         MVC   92(4,13),12(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),16(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC9)
         MVC   92(4,13),16(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),20(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC10)
         MVC   92(4,13),20(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),24(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC11)
         MVC   92(4,13),24(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         CLR   2,4
         BE    @@L45
         MVC   184(4,13),=F'0'
         MVC   88(4,13),=A(@@F10)
         ST    2,92(13)
         B     @@L55
@@L53    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC12)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         ST    4,188(13)
         LTR   4,4
         BE    @@L45
@@L51    EQU   *
         L     2,188(13)
         MVC   88(4,13),=A(@@LC5)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F8)
         MVC   92(4,13),16(2)
         LA    3,104(,13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         CLI   104(13),0
         BE    @@L50
         MVC   88(4,13),=A(@@LC6)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L50    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@F7)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC7)
         ST    2,92(13)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),12(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC8)
         MVC   92(4,13),12(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),16(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC9)
         MVC   92(4,13),16(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),20(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC10)
         MVC   92(4,13),20(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),24(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC11)
         MVC   92(4,13),24(2)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         MVC   188(4,13),=F'0'
         MVC   88(4,13),=A(@@F11)
         ST    2,92(13)
         LA    2,188(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         L     2,188(13)
         LTR   2,2
         BNE   @@L51
@@L45    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function dump_sa epilogue
         PDPEPIL
* Function dump_sa literal pool
         DS    0F
         LTORG
* Function dump_sa page table
         DS    0F
@@PGT6   EQU   *
         DC    A(@@PG6)
         
&FUNC    SETC 'suppress_dump'
@@LC13   EQU   *
         DC    C'suppress dump requested'
         DC    X'0'
         DS    0F
* Function suppress_dump,F13 prologue
@@F13    PDPPRLG CINDEX=7,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN7
         LTORG
@@FEN7   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG7    EQU   *
         LR    11,1
         L     10,=A(@@PGT7)
* Function suppress_dump code
         L     2,0(11)
         MVC   88(4,13),=A(@@LC13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         NI    4(2),127
         SLR   15,15
* Function suppress_dump epilogue
         PDPEPIL
* Function suppress_dump literal pool
         DS    0F
         LTORG
* Function suppress_dump page table
         DS    0F
@@PGT7   EQU   *
         DC    A(@@PG7)
         
&FUNC    SETC 'snap_dump'
@@LC14   EQU   *
         DC    C'snap dump requested'
         DC    X'0'
@@LC15   EQU   *
         DC    C'OPEN for SNAP DD failed, rc=%d'
         DC    X'0'
         DS    0F
* Function snap_dump,F14 prologue
@@F14    PDPPRLG CINDEX=8,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN8
         LTORG
@@FEN8   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG8    EQU   *
         LR    11,1
         L     10,=A(@@PGT8)
* Function snap_dump code
         L     3,0(11)
         MVC   88(4,13),=A(@@LC14)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         OPEN  (SNAPDCB,(OUTPUT))         Open SNAP DCB
                  LR 2,15
         LTR   2,2
         BE    @@L58
         MVC   88(4,13),=A(@@LC15)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L59
@@L58    EQU   *
         LA    2,SNAPDCB
         SNAP DCB=(2),SDATA=ALL,PDATA=ALL
         CLOSE SNAPDCB                    Close the SNAP DCB
         L     12,0(,10)
         NI    4(3),127
@@L59    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function snap_dump epilogue
         PDPEPIL
* Function snap_dump literal pool
         DS    0F
         LTORG
* Function snap_dump page table
         DS    0F
@@PGT8   EQU   *
         DC    A(@@PG8)
         
SNAPDCB  DCB   DDNAME=SNAP,DSORG=PS,LRECL=125,BLKSIZE=1632,            @
               RECFM=VBA,MACRF=(W)
         
&FUNC    SETC 'system_dump'
@@LC16   EQU   *
         DC    C'system_dump requested'
         DC    X'0'
         DS    0F
* Function system_dump,F15 prologue
@@F15    PDPPRLG CINDEX=9,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN9
         LTORG
@@FEN9   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG9    EQU   *
         LR    11,1
         L     10,=A(@@PGT9)
* Function system_dump code
         MVC   88(4,13),=A(@@LC16)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L61    EQU   *
         SLR   15,15
* Function system_dump epilogue
         PDPEPIL
* Function system_dump literal pool
         DS    0F
         LTORG
* Function system_dump page table
         DS    0F
@@PGT9   EQU   *
         DC    A(@@PG9)
         
&FUNC    SETC 'recovery'
@@LC17   EQU   *
         DC    C'libc370 recovery: abend during task termination,'
         DC    C' cleanup only'
         DC    X'0'
@@LC18   EQU   *
         DC    C'S%03X'
         DC    X'0'
@@LC19   EQU   *
         DC    C'U%04d'
         DC    X'0'
@@LC20   EQU   *
         DC    C'%-8.8s'
         DC    X'0'
@@LC21   EQU   *
         DC    C'ABEND %s detected for module %s %s TCB=%08X'
         DC    X'0'
@@LC22   EQU   *
         DC    C'PSW:%08X %08X KEY(%u) MODE(%s) ILC(%u) CC(%u)'
         DC    X'0'
@@LC23   EQU   *
         DC    C'PROB'
         DC    X'0'
@@LC24   EQU   *
         DC    C'SUP'
         DC    X'0'
@@LC25   EQU   *
         DC    C'>>>:%08X:%s'
         DC    X'0'
@@LC26   EQU   *
         DC    C'libc370 recovery: CRT unavailable, register/trac'
         DC    C'eback dump skipped'
         DC    X'0'
         DS    0F
* Function recovery,F16 prologue
@@F16    PDPPRLG CINDEX=10,FRAME=384,BASER=12,ENTRY=NO
         B     @@FEN10
         LTORG
@@FEN10  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG10   EQU   *
         LR    11,1
         L     10,=A(@@PGT10)
* Function recovery code
         L     4,0(11)
         L     5,4(11)
         LA    8,1(0,0)
         SLR   3,3
         L     9,540(3)
         IC    2,235(4)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L63
         L     2,=A(@@LC17)
         MVC   240(62,13),0(2)
         LA    2,240(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
         STC   3,252(4)
         ST    3,240(4)
         B     @@L62
@@L63    EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L64
         L     2,4(5)
         LTR   2,2
         BE    @@L64
         LR    8,2
@@L64    EQU   *
         L     12,0(,10)
         L     3,4(4)
         LR    2,3
         N     2,=F'16773120'
         LA    5,136(,13)
         LTR   2,2
         BE    @@L65
         SRL   2,12
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC18)
         ST    2,96(13)
         B     @@L87
@@L65    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=A(@@LC19)
         N     3,=F'4095'
         ST    3,96(13)
@@L87    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         A     4,=F'104'
         LA    7,376(,13)
         MVC   0(8,7),0(4)
         A     4,=F'-104'
         LA    2,120(,13)
         CLI   88(4),64
         BH    @@L67
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC2)
         MVC   96(4,13),96(4)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         B     @@L68
@@L86    EQU   *
         SLR   2,2
         STC   2,120(13,3)
         B     @@L68
@@L67    EQU   *
         L     12,0(,10)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC20)
         A     4,=F'88'
         ST    4,96(13)
         A     4,=F'-88'
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         SLR   3,3
         LR    5,2
@@L73    EQU   *
         IC    2,0(5)
         SLL   2,24
         SRA   2,24
         C     2,=F'64'
         BE    @@L86
         A     3,=F'1'
         A     5,=F'1'
         LA    2,7(0,0)
         CR    3,2
         BNH   @@L73
@@L68    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@F6)
         ST    4,92(13)
         LA    6,160(,13)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC21)
         LA    2,136(,13)
         ST    2,92(13)
         LA    2,120(,13)
         ST    2,96(13)
         ST    6,100(13)
         ST    9,104(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         IC    5,20(4)
         N     5,=F'192'
         SRA   5,5
         IC    15,106(4)
         N     15,=F'48'
         SRA   15,4
         MVC   88(4,13),=A(@@LC22)
         MVC   92(4,13),376(13)
         MVC   96(4,13),4(7)
         SLR   2,2
         IC    2,105(4)
         LR    3,2
         SRL   3,4
         ST    3,100(13)
         N     2,=F'1'
         L     3,=A(@@LC23)
         LTR   2,2
         BNE   @@L75
         L     3,=A(@@LC24)
@@L75    EQU   *
         L     12,0(,10)
         ST    3,104(13)
         ST    5,108(13)
         ST    15,112(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LR    3,7
         A     3,=F'4'
         L     2,0(3)
         N     2,=F'16777215'
         ST    2,0(3)
         CLR   2,5
         BNH   @@L76
         SR    2,5
         ST    2,0(3)
@@L76    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@F7)
         MVC   92(4,13),0(3)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
         MVC   88(4,13),=A(@@LC25)
         MVC   92(4,13),0(3)
         ST    6,96(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L77
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F12)
         BALR  14,15
         B     @@L78
@@L77    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC26)
         MVC   304(67,13),0(2)
         LA    2,304(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
@@L78    EQU   *
         L     12,0(,10)
         LA    2,2(0,0)
         CR    8,2
         BE    @@L82
         BH    @@L84
         LTR   8,8
         BE    @@L80
         B     @@L79
@@L84    EQU   *
         L     12,0(,10)
         LA    2,3(0,0)
         CLR   8,2
         BE    @@L83
         B     @@L79
@@L80    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F13)
         BALR  14,15
         B     @@L79
@@L82    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F14)
         BALR  14,15
         B     @@L79
@@L83    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F15)
         BALR  14,15
@@L79    EQU   *
         L     12,0(,10)
         MVI   252(4),0
         MVC   240(4,4),=F'0'
@@L62    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function recovery epilogue
         PDPEPIL
* Function recovery literal pool
         DS    0F
         LTORG
* Function recovery page table
         DS    0F
@@PGT10  EQU   *
         DC    A(@@PG10)
         DS    0F
* X-func __abrpt prologue
@@ABRPT  PDPPRLG CINDEX=11,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN11
         LTORG
@@FEN11  EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG11   EQU   *
         LR    11,1
         L     10,=A(@@PGT11)
* Function __abrpt code
         L     2,0(11)
         L     15,=F'-1'
         LA    3,2(0,0)
         CLR   2,3
         BH    @@L89
         ST    2,88(13)
         MVC   92(4,13),=A(@@F16)
         MVC   96(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@ESTAE)
         BALR  14,15
@@L89    EQU   *
         L     12,0(,10)
* Function __abrpt epilogue
         PDPEPIL
* Function __abrpt literal pool
         DS    0F
         LTORG
* Function __abrpt page table
         DS    0F
@@PGT11  EQU   *
         DC    A(@@PG11)
         END
