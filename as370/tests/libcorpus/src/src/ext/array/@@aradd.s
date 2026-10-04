         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'arrayadd'
* Program text area
@@LC0    EQU   *
         DC    C'ARRY'
         DC    X'0'
         DS    0F
* X-func *@@ARADD prologue
@@ARADD  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ARADD code
         L     9,0(11)
         MVC   96(4,13),=F'0'
         LTR   9,9
         BE    @@L10
         L     2,0(9)
         LTR   2,2
         BNE   @@L4
         MVC   88(4,13),=F'20'
         LA    1,88(,13)
         L     15,=V(@@ARNEW)
         BALR  14,15
         ST    15,0(9)
@@L4     EQU   *
         L     12,0(,10)
         L     5,0(9)
         LTR   5,5
         BE    @@L11
         LR    6,5
         A     6,=F'-12'
         L     2,=A(@@LC0)
         CLC   0(4,6),0(2)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L6
@@L10    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         B     @@L9
@@L6     EQU   *
         L     12,0(,10)
         L     2,4(6)
         CL    2,8(6)
         BH    @@L7
         SLL   2,2
         LR    8,2
         A     8,=F'12'
         A     2,=F'92'
         MVC   88(4,13),=F'1'
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    7,15
         LTR   15,15
         BNE   @@L8
@@L11    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'12'
@@L9     EQU   *
         L     12,0(,10)
         MVC   96(4,13),=F'-1'
         B     @@L3
@@L8     EQU   *
         L     12,0(,10)
         LR    4,15
         LR    5,8
         LR    2,6
         LR    3,8
         MVCL  4,2
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         LR    6,7
         L     2,4(7)
         A     2,=F'20'
         ST    2,4(7)
         A     6,=F'12'
         ST    6,0(9)
         A     6,=F'-12'
@@L7     EQU   *
         L     12,0(,10)
         LR    5,6
         A     5,=F'8'
         L     2,0(5)
         L     4,0(9)
         LR    3,2
         SLL   3,2
         L     6,4(11)
         ST    6,0(3,4)
         A     2,=F'1'
         ST    2,0(5)
@@L3     EQU   *
         L     12,0(,10)
         L     15,96(13)
* Function *@@ARADD epilogue
         PDPEPIL
* Function *@@ARADD literal pool
         DS    0F
         LTORG
* Function *@@ARADD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
