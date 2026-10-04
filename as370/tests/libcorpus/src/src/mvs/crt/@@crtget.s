         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'__CRTGET'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s CRT for TCB(%08X) was not found in PPA(%08X)'
         DC    X'0'
@@LC1    EQU   *
         DC    C'PPACRT'
         DC    X'0'
         DS    0F
* X-func __CRTGET prologue
@@CRTGET PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __CRTGET code
         SLR   2,2
         L     7,540(2)
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    4,15
         LR    6,2
         LR    5,2
         LTR   15,15
         BE    @@L14
         ST    15,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L14
         A     4,=F'12'
         ST    4,88(13)
         A     4,=F'-12'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,15
         LR    15,2
         CLR   2,5
         BNL   @@L6
@@L9     EQU   *
         L     2,12(4)
         LR    3,15
         SLL   3,2
         L     3,0(3,2)
         L     2,8(3)
         CLR   2,7
         BNE   @@L7
         LR    6,3
         B     @@L6
@@L7     EQU   *
         L     12,0(,10)
         A     15,=F'1'
         CLR   15,5
         BL    @@L9
@@L6     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         LTR   6,6
         BNE   @@L11
@@L14    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         ST    7,96(13)
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         LTR   4,4
         BE    @@L11
         LTR   5,5
         BE    @@L11
         MVC   88(4,13),12(4)
         SLL   5,2
         ST    5,92(13)
         MVC   96(4,13),=A(@@LC1)
         LA    1,88(,13)
         L     15,=V(WTODUMPF)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         LR    15,6
* Function __CRTGET epilogue
         PDPEPIL
* Function __CRTGET literal pool
         DS    0F
         LTORG
* Function __CRTGET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
