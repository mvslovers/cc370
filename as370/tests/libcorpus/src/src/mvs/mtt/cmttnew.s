         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'*CMTT*'
         DC    X'0'
         DS    0F
* X-func *CMTTNEW prologue
CMTTNEW  PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *CMTTNEW code
         SLR   9,9
         L     2,16(9)
         L     3,148(2)
         LR    7,9
         ST    9,100(13)
         ST    9,104(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@PSWKEY)
         BALR  14,15
         LTR   15,15
         BE    @@L2
         LA    1,88(,13)
         L     15,=V(@@AUTASK)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         MVC   100(4,13),=F'1'
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@PSWKEY)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LTR   15,15
         BE    @@L5
         MVC   104(4,13),=F'1'
@@L5     EQU   *
         L     12,0(,10)
         ST    7,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@SUPER)
         BALR  14,15
         L     6,140(3)
         L     8,16(6)
         N     8,=F'16777215'
         MVC   88(4,13),=F'128'
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@PROB)
         BALR  14,15
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BE    @@L4
         L     2,=A(@@LC0)
         MVC   0(7,15),0(2)
         MVC   88(4,13),=F'1'
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,8(7)
         LTR   15,15
         BNE   @@L7
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LR    7,9
         B     @@L4
@@L7     EQU   *
         L     12,0(,10)
         ST    9,88(13)
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(@@SUPER)
         BALR  14,15
         L     4,8(7)
         LR    5,8
         LR    2,6
         LR    3,8
         MVCL  4,2
         L     3,4(6)
         SR    3,6
         L     2,8(7)
         AR    3,2
         ST    3,4(2)
         L     3,8(6)
         SR    3,6
         L     2,8(7)
         AR    3,2
         ST    3,8(2)
         L     3,12(6)
         SR    3,6
         L     2,8(7)
         AR    3,2
         ST    3,12(2)
         L     2,8(7)
         STC   9,16(2)
         L     3,32(6)
         SR    3,6
         L     2,8(7)
         AR    3,2
         ST    3,32(2)
         MVC   88(4,13),=F'128'
         ST    9,92(13)
         LA    1,88(,13)
         L     15,=V(@@PROB)
         BALR  14,15
         L     6,8(7)
         ST    9,36(6)
         ST    9,44(6)
         A     6,=F'48'
         LA    2,64(0,0)
         
*** MEMSET ***
         LR    14,6           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,9            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         AR    6,2
         LA    2,16(0,0)
         
*** MEMSET ***
         LR    14,6           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,9            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L4     EQU   *
         L     12,0(,10)
         IC    2,96(13)
         L     3,104(13)
         LTR   3,3
         BE    @@L10
         N     2,=XL4'000000FF'
         ST    2,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@SUPER)
         BALR  14,15
         B     @@L11
@@L10    EQU   *
         L     12,0(,10)
         N     2,=XL4'000000FF'
         ST    2,88(13)
         MVC   92(4,13),104(13)
         LA    1,88(,13)
         L     15,=V(@@PROB)
         BALR  14,15
@@L11    EQU   *
         L     12,0(,10)
         L     2,100(13)
         LTR   2,2
         BE    @@L12
         LA    1,88(,13)
         L     15,=V(@@UATASK)
         BALR  14,15
@@L12    EQU   *
         L     12,0(,10)
         LR    15,7
* Function *CMTTNEW epilogue
         PDPEPIL
* Function *CMTTNEW literal pool
         DS    0F
         LTORG
* Function *CMTTNEW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
