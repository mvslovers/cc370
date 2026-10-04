         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'failed'
* Program text area
@@LC0    EQU   *
         DC    C'libc370 @@@try.c failed(): recovery cleanup-only'
         DC    C', retry suppressed'
         DC    X'0'
         DS    0F
* Function failed,F6 prologue
@@F6     PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function failed code
         L     3,0(11)
         L     2,4(11)
         L     15,4(2)
         L     4,4(3)
         N     4,=F'16777215'
         SLR   5,5
         IC    2,235(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L2
         L     2,=A(@@LC0)
         MVC   96(67,13),0(2)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
         STC   5,252(3)
         ST    5,240(3)
         LR    15,5
         B     @@L1
@@L2     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L3
         ST    4,60(15)
@@L3     EQU   *
         L     5,=A(RETRY)
         L     12,0(,10)
         MVI   4(3),0
         A     3,=F'136'
         MVC   0(64,3),0(15)
         A     3,=F'-136'
         MVI   252(3),4
         ST    5,240(3)
         OI    253(3),8
         LA    15,4(0,0)
@@L1     EQU   *
         L     12,0(,10)
* Function failed epilogue
         PDPEPIL
* Function failed literal pool
         DS    0F
         LTORG
* Function failed page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'call'
@@LC1    EQU   *
         DC    C'libc370 @@@try.c call(): FREEMAIN of an abandone'
         DC    C'd PPA failed, walk stopped'
         DC    X'0'
         DS    0F
* Function call,F7 prologue
@@F7     PDPPRLG CINDEX=1,FRAME=256,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function call code
         L     6,0(11)
         L     3,4(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    9,15
         MVC   248(4,13),=F'0'
         SLR   4,4
         L     2,540(4)
         L     2,112(2)
         N     2,=F'16777215'
         LTR   2,2
         BE    @@L5
         LR    4,2
         A     4,=F'8'
         MVC   248(4,13),0(4)
@@L5     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         STM   0,14,0(2)
         MVC   164(4,13),=F'-1'
         LTR   9,9
         BE    @@L6
         MVC   376(4,9),=F'0'
@@L6     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@F6)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@ESTAE)
         BALR  14,15
         LTR   15,15
         BE    @@L7
         LCR   5,15
         B     @@L8
@@L20    EQU   *
         L     2,=A(@@LC1)
         MVC   168(75,13),0(2)
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
         B     @@L11
@@L7     EQU   *
         LR    15,6          => function to call 
         LR    1,3           => parameter list
         BALR  14,15         call function
         SR    15,15         function completed without abend
         LR    5,15         save return code
         L     12,0(,10)
         LTR   5,5
         BE    @@L10
         
RETRY    DS   0H
         LR    5,15
         LTR   4,4
         BE    @@L11
         L     3,0(4)
         MVC   0(4,4),248(13)
         LTR   3,3
         BE    @@L11
         CL    3,248(13)
         BE    @@L11
         L     2,=F'16777215'
         CLR   3,2
         BH    @@L11
         LA    8,1(0,0)
@@L17    EQU   *
         LR    7,3
         L     2,0(3)
         L     4,=F'2094520257'
         CLR   2,4
         BNE   @@L11
         L     4,36(3)
         SLR   6,6
         IC    6,33(3)
         LR    2,4
         BCTR  2,0
         L     15,=F'16777214'
         CLR   2,15
         BH    @@L11
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@PPAHRV)
         BALR  14,15
         L     3,20(3)
         FREEMAIN RC,A=(7),LV=(4),SP=(6)
         LR    2,15
         LTR   2,2
         BNE   @@L20
         LTR   3,3
         BE    @@L11
         CL    3,248(13)
         BE    @@L11
         L     2,=F'16777215'
         CLR   3,2
         BH    @@L11
         LR    2,8
         A     8,=F'1'
         LA    4,15(0,0)
         CLR   2,4
         BNH   @@L17
@@L11    EQU   *
         L     12,0(,10)
         N     5,=F'16777215'
         LTR   9,9
         BE    @@L10
         ST    5,376(9)
@@L10    EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'2'
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ESTAE)
         BALR  14,15
@@L8     EQU   *
         L     12,0(,10)
         LR    15,5
* Function call epilogue
         PDPEPIL
* Function call literal pool
         DS    0F
         LTORG
* Function call page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         DS    0F
* X-func ___try prologue
@@@TRY   PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function ___try code
         MVC   88(4,13),0(11)
         LA    2,4(,11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
* Function ___try epilogue
         PDPEPIL
* Function ___try literal pool
         DS    0F
         LTORG
* Function ___try page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         DS    0F
* X-func ___tryrc prologue
@@@TRYRC PDPPRLG CINDEX=3,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function ___tryrc code
         L     2,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L23
         L     2,376(15)
@@L23    EQU   *
         L     12,0(,10)
         LR    15,2
* Function ___tryrc epilogue
         PDPEPIL
* Function ___tryrc literal pool
         DS    0F
         LTORG
* Function ___tryrc page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         END
