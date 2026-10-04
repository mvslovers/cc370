         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'r,record'
         DC    X'0'
@@LC1    EQU   *
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'FF'
         DC    X'0'
         DS    0F
* X-func *@@WALKPD prologue
@@WALKPD PDPPRLG CINDEX=0,FRAME=384,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@WALKPD code
         L     2,0(11)
         MVC   376(4,13),=F'0'
         LTR   2,2
         BE    @@L3
         L     3,8(11)
         LTR   3,3
         BNE   @@L2
@@L3     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'22'
         B     @@L28
@@L2     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),376(13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(FOPEN)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L6
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     2,0(15)
         LTR   2,2
         BNE   @@L28
         B     @@L29
@@L6     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'1'
         MVC   96(4,13),=F'256'
         ST    6,100(13)
         LA    1,88(,13)
         L     15,=V(FREAD)
         BALR  14,15
         LA    8,1(0,0)
         CLR   15,8
         BNH   @@L7
         LH    5,104(13)
         N     5,=XL4'0000FFFF'
         CLR   5,15
         BNH   @@L10
         LR    5,15
@@L10    EQU   *
         L     12,0(,10)
         LA    4,2(0,0)
         LA    9,13(0,0)
         CLR   5,9
         BNH   @@L12
@@L24    EQU   *
         LA    7,104(,13)
         LR    2,7
         AR    2,4
         L     3,=A(@@LC1)
         CLC   0(8,2),0(3)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L15
         IC    3,11(7,4)
         N     3,=F'31'
         AR    3,3
         A     3,=F'12'
         AR    3,4
         CLR   3,5
         BH    @@L12
         L     2,4(11)
         LTR   2,2
         BE    @@L17
         L     8,104(13,4)
         L     9,4+104(13,4)
         ST    8,360(13)
         ST    9,4+360(13)
         SLR   15,15
         IC    2,360(13)
         SLL   2,24
         SRA   2,24
         C     2,=F'64'
         BE    @@L19
         LA    2,360(,13)
@@L21    EQU   *
         A     15,=F'1'
         A     2,=F'1'
         LA    9,7(0,0)
         CR    15,9
         BH    @@L19
         CLI   0(2),64
         BNE   @@L21
@@L19    EQU   *
         L     12,0(,10)
         SLR   2,2
         STC   2,360(15,13)
         LA    2,360(,13)
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@PATMAT)
         BALR  14,15
         LTR   15,15
         BE    @@L13
@@L17    EQU   *
         L     12,0(,10)
         L     8,376(13)
         A     8,=F'1'
         ST    8,376(13)
         MVC   88(4,13),12(11)
         AR    7,4
         ST    7,92(13)
         L     9,8(11)
         LA    1,88(,13)
         LA    15,0(9)
         BALR  14,15
         LTR   15,15
         BNE   @@L15
@@L13    EQU   *
         L     12,0(,10)
         LR    4,3
         LR    2,3
         A     2,=F'12'
         CLR   2,5
         BNH   @@L24
@@L12    EQU   *
         L     12,0(,10)
         LH    2,40(6)
         N     2,=F'1'
         LTR   2,2
         BE    @@L6
@@L7     EQU   *
         L     12,0(,10)
         LH    2,40(6)
         N     2,=F'2'
         LTR   2,2
         BE    @@L15
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
@@L29    EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),=F'5'
@@L28    EQU   *
         L     12,0(,10)
         L     15,=F'-1'
         B     @@L1
@@L15    EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(FCLOSE)
         BALR  14,15
         L     15,376(13)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@WALKPD epilogue
         PDPEPIL
* Function *@@WALKPD literal pool
         DS    0F
         LTORG
* Function *@@WALKPD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
