         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func jesiropn prologue
JESIROPN PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function jesiropn code
         LA    4,96(,13)
         LA    5,9(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         LA    4,96(,13)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L3
         ST    4,88(13)
         MVC   92(4,13),0(11)
         LA    1,88(,13)
         L     15,=A(@@F8)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         L     2,0(15)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@DSFREE)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         ST    2,0(15)
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function jesiropn epilogue
         PDPEPIL
* Function jesiropn literal pool
         DS    0F
         LTORG
* Function jesiropn page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC '__alloc_intrdr'
@@LC0    EQU   *
         DC    C'INTRDR'
         DC    X'0'
         DS    0F
* Function __alloc_intrdr,F7 prologue
@@F7     PDPPRLG CINDEX=1,FRAME=128,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __alloc_intrdr code
         L     6,0(11)
         SLR   15,15
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
         LR    3,15
         LTR   15,15
         BNE   @@L7
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXSYSO)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L7
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@TXPGM)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L7
         ST    2,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@TXCLOS)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BNE   @@L7
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LTR   15,15
         BE    @@L7
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
         LR    3,15
         LTR   15,15
         BNE   @@L7
         L     2,120(13)
         L     2,0(2)
         MVC   0(8,6),6(2)
         LR    15,6
         A     15,=F'8'
         CLR   15,6
         BNH   @@L14
         L     4,=F'-1'
@@L19    EQU   *
         IC    2,0(4,15)
         CLM   2,1,=XL1'40'
         BNE   @@L14
         BCTR  15,0
         CLR   15,6
         BH    @@L19
@@L14    EQU   *
         L     12,0(,10)
         MVI   0(15),0
@@L7     EQU   *
         L     12,0(,10)
         L     2,120(13)
         LTR   2,2
         BE    @@L17
         LA    2,120(,13)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(@@FRTX9A)
         BALR  14,15
@@L17    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __alloc_intrdr epilogue
         PDPEPIL
* Function __alloc_intrdr literal pool
         DS    0F
         LTORG
* Function __alloc_intrdr page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC '__vsam_open_intrdr'
@@LC1    EQU   *
         DC    C'*VSFILE*'
         DC    X'0'
         DS    0F
* Function __vsam_open_intrdr,F8 prologue
@@F8     PDPPRLG CINDEX=2,FRAME=176,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function __vsam_open_intrdr code
         L     7,4(11)
         MVC   168(4,13),=F'0'
         SLR   4,4
         LR    6,4
         LA    4,104(,13)
         LA    5,64(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'188'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    4,15
         LTR   15,15
         BE    @@L29
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'80'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNE   @@L23
@@L29    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'12'
         B     @@L22
@@L23    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC1)
         MVC   0(9,4),0(2)
         A     4,=F'8'
         ST    4,88(13)
         A     4,=F'-8'
         MVC   92(4,13),=F'8'
         MVC   96(4,13),0(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         STC   6,21(4)
         STC   6,22(4)
         STC   6,23(4)
         ST    4,180(4)
         LR    6,4
         A     6,=F'24'
         MVC   0($ACBLEN,6),ACBMODEL    Copy prototype ACB
         MVC   40(8,6),8(4)
         A     4,=F'104'
         MVC   0($RPLLEN,4),RPLMODEL    Copy prototype RPL
         A     4,=F'-104'
         LR    3,4
         A     3,=F'104'
         A     4,=F'24'
         LA    2,104(,13)
         MODCB RPL=(3),ACB=((4)),MF=(G,(2))
         A     4,=F'-24'
         A     3,=F'-80'
         LA    2,104(,13)
         MODCB ACB=(3),MF=(G,(2))
         A     4,=F'104'
         MODCB RPL=(4),AREA=(5),AREALEN=80,RECLEN=80,MF=(G,(2))
         A     4,=F'-104'
         MVC   0($OPNLEN,2),OPNMODEL    Copy prototype OPEN
         OPEN  ((3)),MF=(E,(2))
         ST    15,168(13)
         IC    2,48(6)
         N     2,=F'16'
         LTR   2,2
         BE    @@L24
         OI    17(4),128
         MVC   168(4,13),=F'0'
         B     @@L22
@@L24    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'153'
@@L22    EQU   *
         L     12,0(,10)
         L     2,168(13)
         LTR   2,2
         BE    @@L26
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),168(13)
         LTR   4,4
         BE    @@L26
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F9)
         BALR  14,15
         SLR   4,4
@@L26    EQU   *
         L     12,0(,10)
         LTR   7,7
         BE    @@L28
         ST    4,0(7)
@@L28    EQU   *
         L     12,0(,10)
         L     15,168(13)
* Function __vsam_open_intrdr epilogue
         PDPEPIL
* Function __vsam_open_intrdr literal pool
         DS    0F
         LTORG
* Function __vsam_open_intrdr page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         
&FUNC    SETC '__vsam_close_intrdr'
         DS    0F
* Function __vsam_close_intrdr,F9 prologue
@@F9     PDPPRLG CINDEX=3,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN3
         LTORG
@@FEN3   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG3    EQU   *
         LR    11,1
         L     10,=A(@@PGT3)
* Function __vsam_close_intrdr code
         L     15,0(11)
         LTR   15,15
         BE    @@L32
         L     2,136(15)
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(@@VSCLOS)
         BALR  14,15
         LTR   2,2
         BE    @@L32
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
@@L32    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function __vsam_close_intrdr epilogue
         PDPEPIL
* Function __vsam_close_intrdr literal pool
         DS    0F
         LTORG
* Function __vsam_close_intrdr page table
         DS    0F
@@PGT3   EQU   *
         DC    A(@@PG3)
         DS    0F
OPNMODEL OPEN (ACBMODEL),MF=L
$OPNLEN  EQU   *-OPNMODEL
         DS    0F
ACBMODEL ACB   AM=VSAM,DDNAME=X,MACRF=(ADR,SEQ,OUT)
         DS    0F
RPLMODEL RPL   AM=VSAM,ACB=ACBMODEL,OPTCD=(ADR,SEQ,SYN,NUP,MVE)
         IFGACB
$ACBLEN  EQU   *-IFGACB
         IFGRPL
$RPLLEN  EQU   *-IFGRPL
         END
