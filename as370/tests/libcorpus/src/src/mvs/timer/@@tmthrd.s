         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_thread'
* Program text area
         DS    0F
* X-func *@@TMTHRD prologue
@@TMTHRD PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMTHRD code
         L     4,0(11)
         SLR   7,7
         LR    3,7
         MVC   112(4,13),=F'100'
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    7,15
         OI    8(4),64
         ST    3,16(4)
         A     4,=F'24'
         ST    4,88(13)
         A     4,=F'-24'
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         LPR   15,15
         LCR   15,15
         SRL   15,1
         N     15,=F'1073741824'
         ST    15,20(4)
@@L42    EQU   *
         LTR   7,7
         BNE   @@L4
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         LTR   4,4
         BE    @@L6
         IC    3,8(4)
         N     3,=F'16'
         LTR   3,3
         BNE   @@L6
         L     2,112(13)
         LTR   2,2
         BNE   @@L8
         MVC   112(4,13),=F'1'
@@L8     EQU   *
         L     12,0(,10)
         LR    5,4
         A     5,=F'16'
         ST    5,104(13)
         LR    6,4
         A     6,=F'20'
         LR    2,6
         O     2,=F'-2147483648'
         ST    2,108(13)
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@TMSECS)
         BALR  14,15
         LA    2,104(,13)
         ST    2,88(13)
         ST    5,92(13)
         MVC   96(4,13),112(13)
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         ST    4,88(13)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    7,15
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(@@TMSECS)
         BALR  14,15
         STD   0,80(,13)
         LM    8,9,80(13)
         L     2,0(5)
         N     2,=F'1073741824'
         LTR   2,2
         BE    @@L9
         ST    3,0(5)
@@L9     EQU   *
         L     12,0(,10)
         L     2,0(6)
         N     2,=F'1073741824'
         LTR   2,2
         BE    @@L10
         ST    3,0(6)
@@L10    EQU   *
         L     12,0(,10)
         LR    6,4
         A     6,=F'24'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@ARCOU)
         BALR  14,15
         IC    2,8(4)
         N     2,=F'32'
         LTR   2,2
         BE    @@L11
         LTR   15,15
         BNE   @@L11
         LTR   7,7
         BNE   @@L6
         ST    4,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
         B     @@L6
@@L11    EQU   *
         L     12,0(,10)
         MVC   112(4,13),=F'200'
         LR    5,15
@@L37    EQU   *
         LTR   5,5
         BE    @@L42
         ST    6,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARGET)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L15
         IC    2,8(15)
         N     2,=F'32'
         LTR   2,2
         BNE   @@L15
         LD    2,16(15)
         STM   8,9,80(13)
         LD    0,80(,13)
         CDR   2,0
         BH    @@L41
         L     2,28(15)
         LTR   2,2
         BE    @@L21
         MVC   88(4,13),=V(@@ECBPST)
         MVC   92(4,13),28(15)
         MVC   96(4,13),40(15)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
@@L21    EQU   *
         L     12,0(,10)
         L     2,32(3)
         LTR   2,2
         BE    @@L22
         ST    2,88(13)
         MVC   92(4,13),36(3)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
@@L22    EQU   *
         L     12,0(,10)
         IC    15,8(3)
         SLL   15,24
         SRA   15,24
         C     15,=F'0'
         BL    @@L23
         ST    3,88(13)
         LA    1,88(,13)
         L     15,=V(FREE)
         BALR  14,15
         ST    6,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(@@ARDEL)
         BALR  14,15
         B     @@L15
@@L23    EQU   *
         L     12,0(,10)
         LR    2,15
         N     2,=F'64'
         LTR   2,2
         BNE   @@L24
         O     15,=F'32'
         STC   15,8(3)
         B     @@L15
@@L24    EQU   *
         L     12,0(,10)
         ST    8,16(3)
         ST    9,4+16(3)
         L     2,24(3)
         LTR   2,2
         BE    @@L25
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LTR   2,2
         BNL   @@L26
         AD    0,=D'4.294967296E+9'
@@L26    EQU   *
         L     12,0(,10)
         DD    0,=D'1.0E+2'
         STM   8,9,80(13)
         LD    2,80(,13)
         ADR   0,2
         AD    0,=D'-6.0000000000000001249001E-3'
         B     @@L38
@@L25    EQU   *
         L     12,0(,10)
         STM   8,9,80(13)
         LD    0,80(,13)
         AD    0,=D'6.0000000000000001249001E-3'
@@L38    EQU   *
         L     12,0(,10)
         STD   0,16(3)
         LD    2,16(3)
         STM   8,9,80(13)
         LD    0,80(,13)
@@L41    EQU   *
         L     12,0(,10)
         SDR   2,0
         AD    2,=D'5.0000000000000001040834E-3'
         MD    2,=D'1.0E+2'
         LDR   0,2
         AD    0,=XL8'4F08000000000000'
         STD   0,80(,13)
         L     15,84(,13)
         CL    15,112(13)
         BNL   @@L15
         ST    15,112(13)
@@L15    EQU   *
         L     12,0(,10)
         BCTR  5,0
         B     @@L37
@@L6     EQU   *
@@L32    EQU   *
         L     12,0(,10)
         ST    4,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         NI    8(4),191
         LTR   15,15
         BNE   @@L33
         ST    4,88(13)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L33    EQU   *
         L     12,0(,10)
         SLR   15,15
* Function *@@TMTHRD epilogue
         PDPEPIL
* Function *@@TMTHRD literal pool
         DS    0F
         LTORG
* Function *@@TMTHRD page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'timed_waitlist'
         DS    0F
* Function timed_waitlist,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=112,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function timed_waitlist code
         L     5,0(11)
         L     3,4(11)
         SLR   6,6
         L     2,540(6)
         L     4,112(2)
         N     4,=F'16777215'
         L     7,0(4)
         LTR   3,3
         BNE   @@L44
         L     3,0(5)
@@L44    EQU   *
         TTIMER CANCEL
         L     12,0(,10)
         ST    6,88(13)
         ST    3,92(13)
         L     2,12(11)
         N     2,=F'1073741823'
         ST    2,96(13)
         LA    2,100(,13)
         L     0,76(,13)       get NAB
         ST    0,0(,2)         save in plist
         LA    2,88(,13)
         ST    2,0(4)
         LA    3,8(,11)
         LA    2,104(,13)
         L     0,=A(EXITDRVR)
         STIMER REAL,(0),BINTVL=(3),ERRET=SAVERC
SAVERC   ST    15,0(,2)
         WAIT ECBLIST=(5)
         TTIMER CANCEL
         ST    7,0(4)
@@L45    EQU   *
         LR    15,6
* Function timed_waitlist epilogue
         PDPEPIL
* Function timed_waitlist literal pool
         DS    0F
         LTORG
* Function timed_waitlist page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
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
