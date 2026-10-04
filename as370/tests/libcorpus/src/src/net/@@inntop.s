         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func *@@INNTOP prologue
@@INNTOP PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@INNTOP code
         SLR   2,2
         SLR   3,3
         ST    2,104(13)
         ST    3,4+104(13)
         ST    2,112(13)
         ST    3,4+112(13)
         LR    8,2
         LR    9,3
         LR    6,2
         LR    7,3
         LA    4,88(,13)
         L     2,0(11)
         LA    3,2(0,0)
         CLR   2,3
         BE    @@L2
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'47'
         B     @@L20
@@L2     EQU   *
         L     12,0(,10)
         L     2,4(11)
         MVC   120(4,13),0(2)
         LA    5,24(0,0)
@@L10    EQU   *
         L     15,120(13)
         SRL   15,0(5)
         ST    15,124(13)
         NC    124(4,13),=F'255'
         L     3,124(13)
         LA    2,99(0,0)
         CLR   3,2
         BNH   @@L6
         ST    3,104(13)
         L     2,104(13)
         L     3,4+104(13)
         SRDL  2,32
         LA    15,100(0,0)
         DR    2,15
         ST    2,104(13)
         ST    3,4+104(13)
         LA    2,240(,3)
         STC   2,0(4)
         A     4,=F'1'
@@L6     EQU   *
         L     12,0(,10)
         L     3,124(13)
         LA    2,9(0,0)
         CLR   3,2
         BNH   @@L7
         ST    3,112(13)
         L     2,112(13)
         L     3,4+112(13)
         SRDL  2,32
         LA    15,10(0,0)
         DR    2,15
         ST    2,112(13)
         ST    3,4+112(13)
         LR    8,3
         SRDL  8,32
         DR    8,15
         LA    2,240(,8)
         STC   2,0(4)
         A     4,=F'1'
@@L7     EQU   *
         L     12,0(,10)
         L     6,124(13)
         SRDL  6,32
         LA    2,10(0,0)
         DR    6,2
         LA    2,240(,6)
         STC   2,0(4)
         A     4,=F'1'
         LR    3,4
         A     4,=F'1'
         LA    2,75(0,0)
         LTR   5,5
         BNE   @@L9
         LR    2,5
@@L9     EQU   *
         L     12,0(,10)
         STC   2,0(3)
         A     5,=F'-8'
         BNL   @@L10
         LR    2,4
         LA    3,88(,13)
         SR    2,3
         CL    2,12(11)
         BNH   @@L11
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'28'
@@L20    EQU   *
         L     12,0(,10)
         SLR   15,15
         B     @@L1
@@L11    EQU   *
         L     12,0(,10)
         SLR   3,3
         CLR   3,2
         BNL   @@L19
         LA    5,88(,13)
@@L15    EQU   *
         IC    15,0(5)
         L     6,8(11)
         STC   15,0(3,6)
         A     3,=F'1'
         A     5,=F'1'
         LR    2,4
         LA    6,88(,13)
         SR    2,6
         CLR   3,2
         BL    @@L15
@@L19    EQU   *
         L     12,0(,10)
         L     15,8(11)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@INNTOP epilogue
         PDPEPIL
* Function *@@INNTOP literal pool
         DS    0F
         LTORG
* Function *@@INNTOP page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
