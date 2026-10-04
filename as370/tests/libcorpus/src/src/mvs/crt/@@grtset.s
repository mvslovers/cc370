         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBGRT '
         DC    X'0'
         DS    0F
* X-func __grtset prologue
@@GRTSET PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __grtset code
         L     2,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L5
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L5
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'80'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         L     2,=A(@@LC0)
         MVC   0(8,15),0(2)
         MVC   8(2,15),=H'80'
         ST    15,280(4)
         ST    15,16(3)
         SLR   2,2
@@L5     EQU   *
         L     12,0(,10)
         LR    15,2
* Function __grtset epilogue
         PDPEPIL
* Function __grtset literal pool
         DS    0F
         LTORG
* Function __grtset page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
