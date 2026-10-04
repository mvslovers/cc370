         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'CLIBCRT '
         DC    X'0'
         DS    0F
* X-func __CRTSET prologue
@@CRTSET PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __CRTSET code
         L     3,=F'-1'
         SLR   2,2
         L     7,540(2)
         MVC   96(4,13),132(7)
         MVC   100(4,13),180(7)
         LA    1,88(,13)
         L     15,=V(@@PPAGET)
         BALR  14,15
         LR    6,15
         LR    8,2
         LTR   15,15
         BE    @@L3
         ST    15,88(13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LTR   15,15
         BNE   @@L3
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'392'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L15
         LR    9,6
         A     9,=F'12'
         ST    9,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LR    5,2
         CLR   2,15
         BNL   @@L7
@@L11    EQU   *
         L     2,12(6)
         LR    3,5
         SLL   3,2
         L     3,0(3,2)
         L     2,8(3)
         CL    2,96(13)
         BNE   @@L8
         LTR   3,3
         BE    @@L7
         L     8,280(3)
         B     @@L7
@@L8     EQU   *
         L     12,0(,10)
         A     5,=F'1'
         CLR   5,15
         BL    @@L11
@@L7     EQU   *
         L     12,0(,10)
         L     2,=A(@@LC0)
         MVC   0(8,4),0(2)
         ST    7,8(4)
         ST    8,280(4)
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
         L     2,84(,13)
         ST    2,52(4)
         MVC   60(4,4),=F'392'
         L     2,100(13)
         MVC   269(1,4),236(2)
         ST    9,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARADD)
         BALR  14,15
         LR    3,15
@@L15    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function __CRTSET epilogue
         PDPEPIL
* Function __CRTSET literal pool
         DS    0F
         LTORG
* Function __CRTSET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
