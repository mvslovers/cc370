         COPY  PDPTOP
         CSECT
         
HASPACE  DCB   DDNAME=HASPACE1,DSORG=DA,MACRF=(RIC),OPTCD=A,           X
               RECFM=F
DCBLEN   EQU   *-HASPACE
         DCBD  DSORG=DA
         CSECT ,
* Program text area
@@LC0    EQU   *
         DC    C'HASPJS'
         DC    X'0'
         DS    0F
* X-func __jsopen prologue
@@JSOPEN PDPPRLG CINDEX=0,FRAME=4224,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __jsopen code
         L     8,0(11)
         SLR   6,6
         L     9,=F'4216'
         AR    9,13
         MVC   0(4,9),=F'-2147483648'
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'128'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         MVC   0(7,15),0(2)
         LR    7,15
         A     7,=F'24'
         ST    7,16(15)
         L     1,=A(HASPACE)        model DCB for HASPACE
         MVC   0(DCBLEN,7),0(1)   copy model to our dcb area
         SLR   2,2
         IC    2,0(8)
         L     4,=V(@@TOUP)
         L     3,0(4)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L4
         SLR   2,2
         IC    2,1(8)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L4
         CLI   2(8),122
         BNE   @@L4
         LR    15,8
         A     15,=F'3'
         SLR   5,5
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L18
         LR    4,6
         A     4,=F'8'
@@L8     EQU   *
         SLR   2,2
         IC    2,0(5,15)
         L     8,=V(@@TOUP)
         L     3,0(8)
         AR    2,2
         IC    2,1(2,3)
         STC   2,0(4)
         A     5,=F'1'
         A     4,=F'1'
         LA    2,7(0,0)
         CR    5,2
         BH    @@L6
         IC    2,0(15)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L8
@@L6     EQU   *
         L     12,0(,10)
         LA    3,7(0,0)
         CR    5,3
         BH    @@L17
@@L18    EQU   *
         L     12,0(,10)
         LR    2,5
         AR    2,6
         A     2,=F'8'
@@L11    EQU   *
         MVI   0(2),64
         A     5,=F'1'
         A     2,=F'1'
         LA    4,7(0,0)
         CR    5,4
         BNH   @@L11
@@L17    EQU   *
         L     12,0(,10)
         MVC   40(8,7),8(6)
         B     @@L12
@@L4     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         ST    8,92(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LTR   15,15
         BE    @@L12
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@JSCLOS)
         BALR  14,15
         SLR   6,6
         B     @@L3
@@L12    EQU   *
         OPEN  ((7)),MF=(E,(9))
         L     12,0(,10)
         IC    2,48(7)
         N     2,=F'16'
         LTR   2,2
         BNE   @@L14
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@JSCLOS)
         BALR  14,15
         LR    6,2
@@L14    EQU   *
         L     12,0(,10)
         A     6,=F'8'
         LA    2,96(,13)
         DEVTYPE (6),((2),20),DEVTAB
         A     6,=F'-8'
         LH    2,106(13)
         N     2,=XL4'0000FFFF'
         ST    2,20(6)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,6
* Function __jsopen epilogue
         PDPEPIL
* Function __jsopen literal pool
         DS    0F
         LTORG
* Function __jsopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'allocate_spool'
         DS    0F
* Function allocate_spool,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=128,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function allocate_spool code
         L     7,0(11)
         SLR   15,15
         L     6,16(7)
         ST    15,120(13)
         LA    4,96(,13)
         LA    5,20(0,0)
         LR    2,15
         LR    3,15
         MVCL  4,2
         LA    2,120(,13)
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXRDDN)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L21
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L21
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSHR)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L21
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L21
         LR    2,15
         BCTR  2,0
         L     4,120(13)
         SLL   2,2
         L     3,0(2,4)
         O     3,=F'-2147483648'
         ST    3,0(2,4)
         MVI   96(13),20
         MVI   97(13),1
         MVI   98(13),64
         MVC   104(4,13),120(13)
         LA    2,96(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L21
         L     2,120(13)
         L     3,0(2)
         MVC   8(8,7),6(3)
         L     2,0(2)
         MVC   40(8,6),6(2)
@@L21    EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L26
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L26    EQU   *
         L     12,0(,10)
         LR    15,4
* Function allocate_spool epilogue
         PDPEPIL
* Function allocate_spool literal pool
         DS    0F
         LTORG
* Function allocate_spool page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
