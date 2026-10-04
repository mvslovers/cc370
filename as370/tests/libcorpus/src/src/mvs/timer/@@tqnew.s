         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tqe_new'
* Program text area
@@LC0    EQU   *
         DC    C'**TQE**'
         DC    X'0'
         DS    0F
* X-func *@@TQNEW prologue
@@TQNEW  PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TQNEW code
         L     6,12(11)
         L     7,16(11)
         SLR   4,4
         L     8,540(4)
         L     2,548(4)
         LH    5,36(2)
         N     5,=XL4'0000FFFF'
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'48'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L2
         L     2,=A(@@LC0)
         MVC   0(8,15),0(2)
         STC   7,8(15)
         STH   5,10(15)
         ST    8,12(15)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@TMSECS)
         BALR  14,15
         MVC   80(4,13),=XL4'4E000000'
         ST    6,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         LTR   6,6
         BNL   @@L3
         AD    2,=D'4.294967296E+9'
@@L3     EQU   *
         L     12,0(,10)
         DD    2,=D'1.0E+2'
         ADR   2,0
         STD   2,16(3)
         ST    6,24(3)
         MVC   28(4,3),0(11)
         MVC   32(4,3),4(11)
         MVC   36(4,3),8(11)
         LA    1,88(,13)
         L     15,=V(@@TMRID)
         BALR  14,15
         ST    15,40(3)
@@L2     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@TQNEW epilogue
         PDPEPIL
* Function *@@TQNEW literal pool
         DS    0F
         LTORG
* Function *@@TQNEW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
