         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'*VSFILE*'
         DC    X'0'
         DS    0F
* X-func __vsopen prologue
@@VSOPEN PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __vsopen code
         L     8,4(11)
         L     7,8(11)
         L     9,12(11)
         MVC   168(4,13),=F'0'
         SLR   6,6
         LA    4,104(,13)
         LA    5,64(0,0)
         LR    2,6
         LR    3,6
         MVCL  4,2
         LA    2,1(0,0)
         CLR   8,2
         BE    @@L3
         LTR   8,8
         BNE   @@L4
         LTR   7,7
         BNE   @@L5
         CLR   9,2
         BNE   @@L3
         B     @@L37
@@L5     EQU   *
         L     12,0(,10)
         LA    3,2(0,0)
         CLR   7,3
         BNE   @@L3
         LA    15,1(0,0)
         CLR   9,15
         BNE   @@L3
         B     @@L37
@@L4     EQU   *
         L     12,0(,10)
         LA    2,2(0,0)
         CLR   8,2
         BNE   @@L3
         CLR   7,2
         BNE   @@L3
         LA    3,1(0,0)
         CLR   9,3
         BE    @@L37
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'1'
         MVC   92(4,13),=F'188'
         LA    1,88(,13)
         L     15,=V(CALLOC)
         BALR  14,15
         LR    6,15
         LTR   15,15
         BNE   @@L15
         MVC   168(4,13),=F'12'
         B     @@L7
@@L15    EQU   *
         L     12,0(,10)
         L     2,=A(@@LC0)
         MVC   0(9,15),0(2)
         A     6,=F'8'
         ST    6,88(13)
         A     6,=F'-8'
         MVC   92(4,13),=F'8'
         MVC   96(4,13),0(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         STC   8,21(6)
         STC   7,22(6)
         STC   9,23(6)
         ST    6,180(6)
         LR    5,6
         A     5,=F'24'
         MVC   0($ACBLEN,5),ACBMODEL    Copy prototype ACB
         MVC   40(8,5),8(6)
         A     6,=F'104'
         MVC   0($RPLLEN,6),RPLMODEL    Copy prototype RPL
         A     6,=F'-104'
         LR    4,6
         A     4,=F'104'
         LR    3,6
         A     3,=F'24'
         LA    2,104(,13)
         MODCB RPL=(4),ACB=((3)),MF=(G,(2))
         LA    15,1(0,0)
         CLR   8,15
         BE    @@L19
         BL    @@L18
         LA    15,2(0,0)
         CLR   8,15
         BNE   @@L20
@@L18    EQU   *
         MODCB ACB=(3),MACRF=(KEY),MF=(G,(2))
         MODCB RPL=(4),OPTCD=(KEY),MF=(G,(2))
         L     12,0(,10)
         B     @@L16
@@L19    EQU   *
         MODCB ACB=(3),MACRF=(ADR),MF=(G,(2))
         MODCB RPL=(4),OPTCD=(ADR),MF=(G,(2))
         L     12,0(,10)
         B     @@L16
@@L20    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'150'
         B     @@L7
@@L16    EQU   *
         L     12,0(,10)
         LA    2,1(0,0)
         CLR   7,2
         BE    @@L23
         BL    @@L22
         LA    3,2(0,0)
         CLR   7,3
         BE    @@L24
         LA    15,3(0,0)
         CLR   7,15
         BE    @@L25
         B     @@L26
@@L23    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(SEQ),MF=(G,(2))
         B     @@L48
@@L24    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(SEQ,DIR),MF=(G,(2))
@@L48    EQU   *
         L     12,0(,10)
         A     6,=F'-24'
         B     @@L30
@@L25    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(ADR),MF=(G,(2))
         A     6,=F'-24'
         B     @@L31
@@L26    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'151'
         B     @@L7
@@L22    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(DIR),MF=(G,(2))
         A     6,=F'-24'
         LA    2,2(0,0)
         CLR   7,2
         BH    @@L32
         LA    3,1(0,0)
         CLR   7,3
         BNL   @@L30
         B     @@L28
@@L32    EQU   *
         L     12,0(,10)
         LA    15,3(0,0)
         CLR   7,15
         BE    @@L31
         B     @@L27
@@L28    EQU   *
         L     12,0(,10)
         A     6,=F'104'
         LA    2,104(,13)
         MODCB RPL=(6),OPTCD=(DIR),MF=(G,(2))
         B     @@L49
@@L30    EQU   *
         L     12,0(,10)
         A     6,=F'104'
         LA    2,104(,13)
         MODCB RPL=(6),OPTCD=(SEQ),MF=(G,(2))
         B     @@L49
@@L31    EQU   *
         L     12,0(,10)
         A     6,=F'104'
         LA    2,104(,13)
         MODCB RPL=(6),OPTCD=(ADR),MF=(G,(2))
@@L49    EQU   *
         L     12,0(,10)
         A     6,=F'-104'
@@L27    EQU   *
         L     12,0(,10)
         LTR   9,9
         BE    @@L34
         LA    2,2(0,0)
         CLR   9,2
         BH    @@L37
         B     @@L36
@@L34    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(IN),MF=(G,(2))
         A     6,=F'-24'
         B     @@L40
@@L37    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'152'
         B     @@L7
@@L36    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MODCB ACB=(6),MACRF=(OUT),MF=(G,(2))
         A     6,=F'-24'
         LA    3,1(0,0)
         CLR   9,3
         BNH   @@L40
         LA    15,2(0,0)
         CLR   9,15
         BE    @@L41
         B     @@L38
@@L40    EQU   *
         L     12,0(,10)
         A     6,=F'104'
         LA    2,104(,13)
         MODCB RPL=(6),OPTCD=(NUP),MF=(G,(2))
         B     @@L50
@@L41    EQU   *
         L     12,0(,10)
         A     6,=F'104'
         MODCB RPL=(6),OPTCD=(UPD),MF=(G,(2))
@@L50    EQU   *
         L     12,0(,10)
         A     6,=F'-104'
@@L38    EQU   *
         L     12,0(,10)
         A     6,=F'24'
         LA    2,104(,13)
         MVC   0($OPNLEN,2),OPNMODEL    Copy prototype OPEN
         OPEN  ((6)),MF=(E,(2))
         ST    15,168(13)
         A     6,=F'-24'
         IC    2,48(5)
         N     2,=F'16'
         LTR   2,2
         BE    @@L42
         OI    17(6),128
         B     @@L7
@@L42    EQU   *
         L     12,0(,10)
         MVC   168(4,13),=F'153'
@@L7     EQU   *
         L     12,0(,10)
         L     2,168(13)
         LTR   2,2
         BE    @@L44
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         MVC   0(4,15),168(13)
         LTR   6,6
         BE    @@L44
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@VSCLOS)
         BALR  14,15
         SLR   6,6
@@L44    EQU   *
         L     12,0(,10)
         L     2,16(11)
         LTR   2,2
         BE    @@L46
         ST    6,0(2)
@@L46    EQU   *
         L     12,0(,10)
         L     15,168(13)
* Function __vsopen epilogue
         PDPEPIL
* Function __vsopen literal pool
         DS    0F
         LTORG
* Function __vsopen page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
OPNMODEL OPEN (ACBMODEL),MF=L
$OPNLEN  EQU   *-OPNMODEL
         DS    0F
ACBMODEL ACB   DDNAME=X,EXLST=EXITLIST
         DS    0F
RPLMODEL RPL   ACB=ACBMODEL
         DS    0F
EXITLIST EXLST LERAD=LERAD,SYNAD=SYNAD,EODAD=EODAD
         DS    0F
EODAD    PDPPRLG CINDEX=0,FRAME=WORKLEN,BASER=12,ENTRY=NO
         USING WORK,R13
*
         ST    R1,PLIST+0          A(RPL)
         LA    R3,4                End Of File Code
         ST    R3,PLIST+4
*
         LA    R1,PLIST
         L     R15,=V(@@VSXEOF)
         BALR  R14,R15
*
         L     R13,4(,R13)         get callers stack
         LR    R14,R2              get return address
         LM    R0,R12,20(R13)      restore registers
         BR    R14                 return to target
         LTORG ,

         DS    0F
LERAD    PDPPRLG CINDEX=0,FRAME=WORKLEN,BASER=12,ENTRY=NO
         USING WORK,R13
*
         ST    R1,PLIST+0          A(RPL)
         LA    R3,8                Logical Error Code
         ST    R3,PLIST+4
*
         LA    R1,PLIST
         L     R15,=V(@@VSXERR)    Common error handler
         BALR  R14,R15
*
         L     R13,4(,R13)         get callers stack
         LR    R14,R2              get return address
         LM    R0,R12,20(R13)      restore registers
         BR    R14                 return to target
         LTORG ,

         DS    0F
SYNAD    PDPPRLG CINDEX=0,FRAME=WORKLEN,BASER=12,ENTRY=NO
         USING WORK,R13
*
         ST    R1,PLIST+0          A(RPL)
         LA    R3,12               Physical Error Code
         ST    R3,PLIST+4
*
         LA    R1,PLIST
         L     R15,=V(@@VSXERR)    Common error handler
         BALR  R14,R15
*
         L     R13,4(,R13)         get callers stack
         LR    R14,R2              get return address
         LM    R0,R12,20(R13)      restore registers
         BR    R14                 return to target
         LTORG ,

         
WORK     DSECT
SAVEAREA DS    18F                                                  00
STKSVLWS DS    A                 PL/I Language Work Space N/A       48
STKSVNAB DS    A                 next available byte      -------+  4C
PLIST    DS    2F                parameter list
WORKLEN  EQU   *-WORK

         IFGACB
$ACBLEN  EQU   *-IFGACB
         IFGRPL
$RPLLEN  EQU   *-IFGRPL
         CSECT ,
         END
