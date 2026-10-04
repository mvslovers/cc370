         COPY  PDPTOP
         CSECT
         
HASPCKPT DCB   DDNAME=HASPCKPT,DSORG=PS,MACRF=(RCP),                   X
               RECFM=U,BLKSIZE=4096
DCBLEN   EQU   *-HASPCKPT
* Program text area
@@LC0    EQU   *
         DC    C'HASPCP'
         DC    X'0'
         DS    0F
* X-func __cpopen prologue
@@CPOPEN PDPPRLG CINDEX=0,FRAME=4216,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cpopen code
         SLR   8,8
         SLR   9,9
         L     4,0(11)
         L     3,=F'-2147483648'
         L     2,=F'4192'
         ST    3,0(2,13)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'360'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         MVC   0(7,15),0(2)
         LR    7,15
         A     7,=F'256'
         ST    7,16(15)
         L     1,=A(HASPCKPT)        model DCB for HASPCKPT
         MVC   0(DCBLEN,7),0(1)   copy model to our dcb area
         SLR   2,2
         IC    2,0(4)
         L     6,=V(@@TOUP)
         L     3,0(6)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L4
         SLR   2,2
         IC    2,1(4)
         AR    2,2
         LH    2,0(2,3)
         CLM   2,3,=H'196'
         BNE   @@L4
         CLI   2(4),122
         BNE   @@L4
         LR    6,4
         A     6,=F'3'
         SLR   15,15
         IC    2,0(6)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BE    @@L26
         LR    3,5
         A     3,=F'8'
         L     2,=F'4208'
         ST    3,0(2,13)
@@L8     EQU   *
         SLR   2,2
         IC    2,0(15,6)
         L     4,=V(@@TOUP)
         L     3,0(4)
         L     4,=F'4200'
         ST    3,0(4,13)
         AR    2,2
         IC    3,1(2,3)
         L     4,=F'4208'
         L     4,0(4,13)
         STC   3,0(4)
         A     15,=F'1'
         A     4,=F'1'
         L     2,=F'4208'
         ST    4,0(2,13)
         LA    3,7(0,0)
         CR    15,3
         BH    @@L6
         IC    2,0(6)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNE   @@L8
@@L6     EQU   *
         L     12,0(,10)
         LA    4,7(0,0)
         CR    15,4
         BH    @@L23
@@L26    EQU   *
         L     12,0(,10)
         LR    2,15
         AR    2,5
         A     2,=F'8'
@@L11    EQU   *
         MVI   0(2),64
         A     15,=F'1'
         A     2,=F'1'
         LA    6,7(0,0)
         CR    15,6
         BNH   @@L11
@@L23    EQU   *
         L     12,0(,10)
         MVC   40(8,7),8(5)
         B     @@L12
@@L4     EQU   *
         L     12,0(,10)
         ST    5,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LTR   15,15
         BE    @@L12
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@CPCLOS)
         BALR  14,15
         SLR   5,5
         B     @@L3
@@L12    EQU   *
         L     12,0(,10)
         L     2,=F'4192'
         AR    2,13
         OPEN  ((7)),MF=(E,(2))
         IC    2,48(7)
         N     2,=F'16'
         LTR   2,2
         BNE   @@L14
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(@@CPCLOS)
         BALR  14,15
         LR    5,2
         B     @@L3
@@L14    EQU   *
         L     12,0(,10)
         ST    5,88(13)
         MVC   92(4,13),=F'768'
         LA    1,88(,13)
         L     15,=V(@@CPPOIN)
         BALR  14,15
         ST    5,88(13)
         LA    2,96(,13)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@CPREAD)
         BALR  14,15
         MVC   20(204,5),96(13)
         LH    4,206(5)
         N     4,=XL4'0000FFFF'
         A     4,=F'7'
         SLR   2,2
         IC    2,210(5)
         LR    9,4
         SRL   9,3
         MR    8,2
         LR    4,9
         A     4,=F'75'
         N     4,=F'-4'
         ST    4,224(5)
         LH    4,198(5)
         N     4,=XL4'0000FFFF'
         A     4,=F'1'
         LR    2,4
         SLL   2,3
         SR    2,4
         LR    4,2
         SLL   4,2
         A     4,=F'4095'
         SRL   4,12
         LR    3,4
         SLL   3,16
         SRA   3,16
         STH   3,228(5)
         LH    4,200(5)
         N     4,=XL4'0000FFFF'
         A     4,=F'3'
         LR    2,4
         SLL   2,3
         AR    4,2
         SLL   4,2
         A     4,=F'4095'
         SRL   4,12
         LR    2,4
         SLL   2,16
         SRA   2,16
         STH   2,230(5)
         LR    6,2
         N     6,=XL4'0000FFFF'
         N     3,=XL4'0000FFFF'
         AR    6,3
         MVC   88(4,13),=F'1'
         LR    7,6
         SLL   7,12
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         ST    15,236(5)
         LTR   15,15
         BE    @@L3
         ST    7,232(5)
         SLR   4,4
@@L27    EQU   *
         CLR   4,6
         BNL   @@L25
         ST    5,88(13)
         LR    2,4
         SLL   2,12
         A     2,236(5)
         ST    2,92(13)
         LA    1,88(,13)
         L     15,=V(@@CPREAD)
         BALR  14,15
         A     4,=F'1'
         B     @@L27
@@L25    EQU   *
         L     12,0(,10)
         L     3,236(5)
         A     3,=F'28'
         ST    3,240(5)
         A     3,=F'-28'
         LH    4,228(5)
         N     4,=XL4'0000FFFF'
         SLL   4,12
         AR    4,3
         ST    4,244(5)
         LH    2,230(5)
         CLM   2,3,=H'0'
         BE    @@L3
         ST    4,248(5)
         AR    3,7
         ST    3,252(5)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,5
* Function __cpopen epilogue
         PDPEPIL
* Function __cpopen literal pool
         DS    0F
         LTORG
* Function __cpopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'allocate_checkpoint'
         DS    0F
* Function allocate_checkpoint,F6 prologue
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
* Function allocate_checkpoint code
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
         BNE   @@L30
         ST    2,88(13)
         MVC   92(4,13),4(11)
         LA    1,88(,13)
         L     15,=V(@@TXDSN)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L30
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSHR)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BNE   @@L30
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L30
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
         BNE   @@L30
         L     2,120(13)
         L     3,0(2)
         MVC   8(8,7),6(3)
         L     2,0(2)
         MVC   40(8,6),6(2)
@@L30    EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L35
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L35    EQU   *
         L     12,0(,10)
         LR    15,4
* Function allocate_checkpoint epilogue
         PDPEPIL
* Function allocate_checkpoint literal pool
         DS    0F
         LTORG
* Function allocate_checkpoint page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
