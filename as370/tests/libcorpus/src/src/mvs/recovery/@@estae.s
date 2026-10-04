         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'required'
* Program text area
@@LC0    EQU   *
         DC    C'estae() a function pointer is required for ESTAE'
         DC    C' CREATE or OVERLAY'
         DC    X'15'
         DC    X'0'
         DS    0F
* Function required,F2 prologue
@@F2     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function required code
         L     2,0(11)
         LTR   2,2
         BNE   @@L2
         LA    1,88(,13)
         L     15,=V(@@GTERR)
         BALR  14,15
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),0(15)
         LA    1,88(,13)
         L     15,=V(FPUTS)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LR    15,2
* Function required epilogue
         PDPEPIL
* Function required literal pool
         DS    0F
         LTORG
* Function required page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func __estae prologue
@@ESTAE  PDPPRLG CINDEX=1,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function __estae code
         L     2,0(11)
         L     7,8(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    6,15
         L     4,=F'-1'
         SLR   15,15
         LTR   6,6
         BE    @@L5
         LR    3,6
         A     3,=F'188'
         LA    5,1(0,0)
         CLR   2,5
         BH    @@L6
         MVC   88(4,13),4(11)
         LA    1,88(,13)
         L     15,=A(@@F2)
         BALR  14,15
         LTR   15,15
         BE    @@L5
@@L6     EQU   *
         L     12,0(,10)
         LA    5,1(0,0)
         CLR   2,5
         BE    @@L12
         BL    @@L9
         LA    3,2(0,0)
         CLR   2,3
         BE    @@L14
         B     @@L5
@@L9     EQU   *
         L     12,0(,10)
         L     2,184(6)
         LA    5,9(0,0)
         CR    2,5
         BH    @@L5
         LR    5,2
         SLL   5,3
         AR    5,3
         ST    15,0(5)
         ST    7,4(5)
         LA    4,96(,13)
         LA    2,RECOVERY
         LR    3,5               recovery parameter list
         LR    1,4               macro parameter list
         XC    0(16,1),0(1)        clear macro parameter list
         ESTAE (2),CT,PARAM=(3),PURGE=NONE,ASYNCH=YES,TERM=YES,        X
               MF=(E,(1))
         LR    4,15
         LTR   4,4
         BNE   @@L5
         B     @@L16
@@L12    EQU   *
         L     12,0(,10)
         L     2,184(6)
         LTR   2,2
         BNH   @@L13
         BCTR  2,0
         ST    2,184(6)
@@L13    EQU   *
         L     12,0(,10)
         L     5,184(6)
         SLL   5,3
         AR    5,3
         ST    15,0(5)
         ST    7,4(5)
         LA    4,96(,13)
         LA    2,RECOVERY
         LR    3,5               recovery parameter list
         LR    1,4               macro parameter list
         XC    0(16,1),0(1)        clear macro parameter list
         ESTAE (2),OV,PARAM=(3),PURGE=NONE,ASYNCH=YES,TERM=YES,        X
               MF=(E,(1))
         LR    4,15
@@L16    EQU   *
         L     12,0(,10)
         L     2,184(6)
         A     2,=F'1'
         ST    2,184(6)
         B     @@L5
@@L14    EQU   *
         L     12,0(,10)
         L     2,184(6)
         LTR   2,2
         BNH   @@L15
         BCTR  2,0
         ST    2,184(6)
@@L15    EQU   *
         ESTAE 0
         LR    4,15
@@L5     EQU   *
         L     12,0(,10)
         LR    15,4
* Function __estae epilogue
         PDPEPIL
* Function __estae literal pool
         DS    0F
         LTORG
* Function __estae page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
RETRY    DS    0H
         DC    H'0'                 INVALID OPERATION CODE -> S0C1-1
         
RECOVERY DS    0H
         USING RECOVERY,15
         CH    0,=H'12'             Q.SDWA?
         BNE   HAVESDWA             YES, continue
         SR    15,15                NO, percolate ABEND
         BR    14                   RETURN TO RTM=PERCOLATE BY DEFAULT
         LTORG ,
         DROP  15
         
HAVESDWA DS    0H
         STM   14,12,12(13)         SAVE REGISTERS
         LA    12,0(,15)            Establish base register
         USING RECOVERY,12
         LR    3,1                  SAVE POINTER TO SDWA
         USING SDWA,3               MAP SYSTEM DIAGNOSTIC SAVE AREA
         GETMAIN RU,LV=STACKLEN,SP=124
         ST    13,4(1)              chain prev save area
         ST    1,8(13)              chain next save area
         LR    13,1                 => our stack
         USING STACK,13
         LA    1,MAINSTK            stack for called functions
         ST    1,SAVENAB            next available byte in stack
         L     2,SDWAPARM           get parameter address
         ST    3,ARG0               SDWA address
         ST    2,ARG1               udata address
         LA    1,PARMLIST           => C function parameter list
         L     15,0(,2)             => C function to call
         BALR  14,15                call C function
         LR    2,15                 => save return code
         LR    1,13                 => storage to release
         L     13,4(13)             => RTM save area
         FREEMAIN RU,LV=STACKLEN,A=(1),SP=124
         LR    15,2                 restore return code
         DROP 3
         LM    14,12,12(13)         LOAD REGISTERS
         BR    14                   RETURN TO RTM
         IHASDWA                    GENERATE SDWA DSECT
STACK    DSECT
SAVEAREA DS    18F               00 (0)  callers registers go here
SAVELWS  DS    A                 48 (72) PL/I Language Work Space N/A
SAVENAB  DS    A                 4C (76) next available byte -------+
* our stack variables                                               |
PARMLIST DS    0F                plist for C recovery function      |
ARG0     DS    A                 => SDWA                            |
ARG1     DS    A                 => udata                           |
* end of our stack variables                                        |
* start of C function stack area                                    |
         DS    0D                                                   |
MAINSTK  DS    8192F              32K bytes <-----------------------+
MAINLEN  EQU   *-MAINSTK
STACKLEN EQU   *-STACK
         END
