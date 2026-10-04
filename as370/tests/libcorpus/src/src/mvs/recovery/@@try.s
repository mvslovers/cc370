         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'failed'
* Program text area
@@LC0    EQU   *
         DC    C'libc370 __try: recovery cleanup-only, retry supp'
         DC    C'ressed'
         DC    X'0'
         DS    0F
* Function failed,F6 prologue
@@F6     PDPPRLG CINDEX=0,FRAME=152,BASER=12,ENTRY=NO
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
         MVC   96(55,13),0(2)
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
         DC    C'libc370 @@try.c call(): FREEMAIN of an abandoned'
         DC    C' PPA failed, walk stopped'
         DC    X'0'
         DS    0F
* Function call,F7 prologue
@@F7     PDPPRLG CINDEX=1,FRAME=248,BASER=12,ENTRY=NO
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
         L     5,0(11)
         L     3,4(11)
         SLR   9,9
         LR    4,9
         L     2,540(9)
         L     2,112(2)
         N     2,=F'16777215'
         LTR   2,2
         BE    @@L5
         LR    4,2
         A     4,=F'8'
         L     9,0(4)
@@L5     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         STM   0,14,0(2)
         MVC   164(4,13),=F'-1'
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=A(@@F6)
         LA    2,104(,13)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@ESTAE)
         BALR  14,15
         LTR   15,15
         BE    @@L6
         LCR   7,15
         B     @@L7
@@L16    EQU   *
         L     2,=A(@@LC1)
         MVC   168(74,13),0(2)
         LA    2,168(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(WTO)
         BALR  14,15
         B     @@L8
@@L6     EQU   *
         LR    15,5          => function to call 
         LR    1,3           => parameter list
         BALR  14,15         call function
         SR    15,15         function completed without abend
         
RETRY    DS   0H
         LR    7,15
         L     12,0(,10)
         LTR   4,4
         BE    @@L8
         L     3,0(4)
         ST    9,0(4)
         LTR   3,3
         BE    @@L8
         CLR   3,9
         BE    @@L8
         L     2,=F'16777215'
         CLR   3,2
         BH    @@L8
         LA    8,1(0,0)
@@L14    EQU   *
         LR    6,3
         L     2,0(3)
         L     4,=F'2094520257'
         CLR   2,4
         BNE   @@L8
         L     4,36(3)
         SLR   5,5
         IC    5,33(3)
         LR    2,4
         BCTR  2,0
         L     15,=F'16777214'
         CLR   2,15
         BH    @@L8
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@PPAHRV)
         BALR  14,15
         L     3,20(3)
         FREEMAIN RC,A=(6),LV=(4),SP=(5)
         LR    2,15
         LTR   2,2
         BNE   @@L16
         LTR   3,3
         BE    @@L8
         CLR   3,9
         BE    @@L8
         L     2,=F'16777215'
         CLR   3,2
         BH    @@L8
         LR    2,8
         A     8,=F'1'
         LA    4,15(0,0)
         CLR   2,4
         BNH   @@L14
@@L8     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'2'
         MVC   92(4,13),=F'0'
         MVC   96(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ESTAE)
         BALR  14,15
@@L7     EQU   *
         L     12,0(,10)
         LR    15,7
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
* X-func __try prologue
@@TRY    PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function __try code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         MVC   88(4,13),0(11)
         LA    2,4(,11)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LTR   3,3
         BE    @@L18
         ST    15,376(3)
@@L18    EQU   *
         L     12,0(,10)
* Function __try epilogue
         PDPEPIL
* Function __try literal pool
         DS    0F
         LTORG
* Function __try page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         DS    0F
* X-func __tryrc prologue
@@TRYRC  PDPPRLG CINDEX=3,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function __tryrc code
         L     2,=F'-1'
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LTR   15,15
         BE    @@L20
         L     2,376(15)
@@L20    EQU   *
         L     12,0(,10)
         LR    15,2
* Function __tryrc epilogue
         PDPEPIL
* Function __tryrc literal pool
         DS    0F
         LTORG
* Function __tryrc page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         END
