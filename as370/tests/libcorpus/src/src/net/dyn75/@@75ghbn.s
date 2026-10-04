         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'gethostbyname'
* Program text area
         DS    0F
* X-func *@@75GHBN prologue
@@75GHBN PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@75GHBN code
         L     9,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    6,15
         SLR   8,8
         LTR   15,15
         BE    @@L3
         ST    8,64(15)
         ST    8,68(15)
         LR    2,15
         A     2,=F'68'
         ST    2,72(15)
         ST    8,76(15)
         A     6,=F'80'
         LR    3,6
         A     6,=F'-80'
         LR    7,6
         A     7,=F'104'
         ST    7,0(3)
         A     6,=F'64'
         ST    6,4(3)
         MVC   8(4,3),=F'2'
         MVC   12(4,3),=F'4'
         A     6,=F'8'
         ST    6,16(3)
         A     6,=F'-72'
         STC   8,0(7)
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(@@75GABN)
         BALR  14,15
         ST    15,0(2)
         LTR   15,15
         BE    @@L3
         LR    8,3
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         LA    2,79(0,0)
         CLR   15,2
         BNH   @@L5
         LR    15,2
@@L5     EQU   *
         L     12,0(,10)
         LR    4,7
         LR    5,15
         LR    2,9
         LR    3,15
         MVCL  4,2
         SLR   2,2
         STC   2,104(6,15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,8
* Function *@@75GHBN epilogue
         PDPEPIL
* Function *@@75GHBN literal pool
         DS    0F
         LTORG
* Function *@@75GHBN page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
