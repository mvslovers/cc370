         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'gethostbyaddr'
* Program text area
@@LC0    EQU   *
         DC    C'__75ghba() addr=%08X, *addr=%08X'
         DC    X'15'
         DC    X'0'
         DS    0F
* X-func *@@75GHBA prologue
@@75GHBA PDPPRLG CINDEX=0,FRAME=424,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75GHBA code
         L     5,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         SLR   8,8
         LTR   15,15
         BE    @@L3
         LA    2,104(,13)
         XC    0(64,2),0(2)     clear __75 parameter list
         LA    2,168(,13)
         XC    0(256,2),0(2)    clear name buffer
         MVC   64(4,15),=F'0'
         MVC   68(4,15),=F'0'
         LR    2,15
         A     2,=F'68'
         ST    2,72(15)
         MVC   76(4,15),=F'0'
         A     3,=F'80'
         LR    4,3
         A     3,=F'-80'
         LR    6,3
         A     6,=F'104'
         ST    6,0(4)
         A     3,=F'64'
         ST    3,4(4)
         MVC   8(4,4),=F'2'
         MVC   12(4,4),=F'4'
         A     3,=F'8'
         ST    3,16(4)
         A     3,=F'-72'
         STC   8,0(6)
         MVC   0(4,2),0(5)
         MVC   88(4,13),=A(@@LC0)
         ST    5,92(13)
         MVC   96(4,13),0(5)
         LA    1,88(,13)
         L     15,=V(PRINTF)
         BALR  14,15
         LA    7,168(,13)
         ST    7,128(13)
         MVC   132(4,13),=F'18'
         MVC   136(4,13),0(2)
         LA    2,104(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@75)
         BALR  14,15
         CLI   168(13),0
         BE    @@L3
         LR    8,4
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,79(0,0)
         CLR   15,2
         BNH   @@L5
         LR    15,2
@@L5     EQU   *
         L     12,0(,10)
         SLR   5,5
         CR    5,15
         BNL   @@L11
         LR    2,6
         LR    4,7
@@L9     EQU   *
         MVC   0(1,2),0(4)
         A     5,=F'1'
         A     4,=F'1'
         A     2,=F'1'
         CR    5,15
         BL    @@L9
@@L11    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,104(3,15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@75GHBA epilogue
         PDPEPIL
* Function *@@75GHBA literal pool
         DS    0F
         LTORG
* Function *@@75GHBA page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
