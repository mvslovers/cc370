         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ecb_timed_waitlist'
* Program text area
@@LC0    EQU   *
         DC    C'libc370 ecb_timed_waitlist(): STIMER REAL failed'
         DC    C' rc=%d, returning without waiting'
         DC    X'0'
         DS    0F
* X-func *@@ECBTWL prologue
@@ECBTWL PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ECBTWL code
         L     5,0(11)
         L     15,4(11)
         SLR   4,4
         L     2,540(4)
         L     3,112(2)
         N     3,=F'16777215'
         L     6,0(3)
         LTR   15,15
         BNE   @@L2
         L     15,0(5)
@@L2     EQU   *
         L     12,0(,10)
         ST    4,96(13)
         ST    15,100(13)
         L     2,12(11)
         N     2,=F'1073741823'
         ST    2,104(13)
         LA    2,108(,13)
         L     0,76(,13)       get NAB
         ST    0,0(,2)         save in plist
         LA    2,96(,13)
         ST    2,0(3)
         LA    2,8(,11)
         L     0,=A(EXITDRVR)
         STIMER REAL,(0),BINTVL=(2),ERRET=SAVERC
SAVERC   LR    4,15
         LTR   4,4
         BE    @@L3
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         ST    6,0(3)
         LTR   15,15
         BE    @@L4
         IC    3,270(15)
         LR    2,3
         N     2,=F'32'
         LTR   2,2
         BNE   @@L4
         O     3,=F'32'
         STC   3,270(15)
         MVC   88(4,13),=A(@@LC0)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LCR   15,4
         B     @@L1
@@L3     EQU   *
         WAIT ECBLIST=(5)
         TTIMER CANCEL
         L     12,0(,10)
         ST    6,0(3)
         LR    15,4
@@L1     EQU   *
         L     12,0(,10)
* Function *@@ECBTWL epilogue
         PDPEPIL
* Function *@@ECBTWL literal pool
         DS    0F
         LTORG
* Function *@@ECBTWL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
EXITDRVR DS    0H
         SAVE  (14,12),,'EXITDRVR STIMER REAL'
         LA    12,0(,15)
         USING EXITDRVR,12
*
         LA    11,0              A(PSA)
         L     11,X'21C'(,11)    A(TCB) from PSATOLD
         L     11,X'70'(,11)     TCBFSAB first save area
         L     11,0(,11)         A(PLIST) from save area
         LTR   11,11             do we have a plist?
         BNZ   CHKFUNC           yes, continue
         B     RETURN

         
         USING PLIST,11
CHKFUNC  DS    0H
*
* Check function address
         CLC   FUNC,=F'0'        do we have a function to call
         BE    POSTIT            no, try posting ECB directly
*
* Chain stack with callers save area
         L     1,STACKNEW        => stack for function
         ST    13,4(,1)          ... chain stack areas
         ST    1,8(,13)          ... chain stack areas
         LR    13,1              new stack

         
         USING STACK,13
*
* Set next available byte in stack
         LA    0,STACKNAB        next available byte in stack
         ST    0,SAVENAB         next available byte in stack
*
* Call thread function
         L     15,FUNC           get function address from plist
         LA    1,ECB             => parameters for function
         BALR  14,15             call function
*
* Get callers save area
         L     13,SAVEAREA+4     switch back to callers stack
RETURN   DS    0H
         RETURN (14,12)
*
POSTIT   DS    0H
         ICM   1,B'1111',ECB
         BZ    RETURN            no ECB address
         L     0,POSTCODE        vale to post to ECB
         POST  (1),(0)           
         B     RETURN
         LTORG ,
         
STACK    DSECT
SAVEAREA DS    18F               00 (0)  callers registers go here
SAVELWS  DS    A                 48 (72) PL/I Language Work Space N/A
SAVENAB  DS    A                 4C (76) next available byte -------+
         DS    0D                                                   |
STACKNAB DS    0X                50 stack next available byte <-----+
*
         
PLIST    DSECT
FUNC     DS    A                 00 C exit function address
ECB      DS    A                 04 arg1 for C exit
POSTCODE DS    F                 08 arg2 for C exit
STACKNEW DS    A                 0C new stack for C exit
         COPY  CLIBCRT
         CSECT ,
         END
