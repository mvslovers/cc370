         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'getmain'
* Program text area
@V1      EQU   *
         DC    C'getmain'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s request for %u bytes from sp=%u failed, rc=0x'
         DC    C'%02X (%d)'
         DC    X'0'
         DS    0F
* X-func getmain prologue
GETMAIN  PDPPRLG CINDEX=0,FRAME=120,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function getmain code
         L     5,0(11)
         L     4,4(11)
         SLR   6,6
         LR    15,6
         LTR   5,5
         BE    @@L1
         L     2,=F'16777215'
         CLR   5,2
         BH    @@L1
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LTR   15,15
         BE    @@L4
         LA    3,112(,13)
         IPK   0             get psw key in R2
         STC   2,0(,3)      save psw key
         B     @@L5
@@L4     EQU   *
         L     12,0(,10)
         L     2,540(6)
         MVC   112(1,13),28(2)
@@L5     EQU   *
         L     12,0(,10)
         N     4,=F'255'
         A     5,=F'71'
         LR    2,5
         N     2,=F'16777152'
         A     5,=F'-71'
         GETMAIN RC,LV=(2),SP=(4)
         LR    3,15              save the return code
         LR    6,1               save the returned address
         LTR   3,3
         BE    @@L6
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=A(@V1)
         ST    2,96(13)
         ST    4,100(13)
         ST    3,104(13)
         ST    3,108(13)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         SLR   6,6
         B     @@L9
@@L6     EQU   *
         
*** MEMCLR ***
         LR    14,6           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         SLR   1,1             zero fill
         MVCL  14,0            Set target to fill character
         L     12,0(,10)
         SLL   4,24
         OR    4,2
         ST    4,0(6)
         IC    2,112(13)
         SLL   2,24
         OR    2,5
         ST    2,4(6)
         A     6,=F'8'
@@L9     EQU   *
         L     12,0(,10)
         LR    15,6
@@L1     EQU   *
         L     12,0(,10)
* Function getmain epilogue
         PDPEPIL
* Function getmain literal pool
         DS    0F
         LTORG
* Function getmain page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'freemain'
@V2      EQU   *
         DC    C'freemain'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s duplicate freemain'
         DC    X'0'
@@LC2    EQU   *
         DC    C'%s check storage prefix'
         DC    X'0'
         DS    0F
* X-func freemain prologue
FREEMAIN PDPPRLG CINDEX=1,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function freemain code
         L     3,0(11)
         SLR   2,2
         LTR   3,3
         BE    @@L12
         A     3,=F'-8'
         SLR   5,5
         IC    5,0(3)
         L     4,0(3)
         N     4,=F'16777215'
         L     2,4(3)
         N     2,=F'16777215'
         LTR   4,4
         BE    @@L14
         LTR   2,2
         BNE   @@L13
@@L14    EQU   *
         L     12,0(,10)
         ST    3,88(13)
         MVC   92(4,13),=F'64'
         MVC   96(4,13),=A(@@LC1)
         B     @@L16
@@L13    EQU   *
         L     12,0(,10)
         LR    6,4
         SR    6,2
         LR    2,6
         A     2,=F'-8'
         LA    6,64(0,0)
         CLR   2,6
         BNH   @@L15
         ST    3,88(13)
         ST    6,92(13)
         MVC   96(4,13),=A(@@LC2)
@@L16    EQU   *
         L     12,0(,10)
         MVC   100(4,13),=A(@V2)
         LA    1,88(,13)
         L     15,=V(WTODUMPF)
         BALR  14,15
         L     15,=F'-1'
         B     @@L10
@@L15    EQU   *
         
         LR    14,3           => target (s)
         LR    15,4           => length (n)
         SLR   0,0             => source (NULL)
         SLR   1,1             => fill 0
         MVCL  14,0            Set target to fill character
         FREEMAIN RC,A=(3),LV=(4),SP=(5)
         LR    2,15
@@L12    EQU   *
         L     12,0(,10)
         LR    15,2
@@L10    EQU   *
         L     12,0(,10)
* Function freemain epilogue
         PDPEPIL
* Function freemain literal pool
         DS    0F
         LTORG
* Function freemain page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         IKJTCB DSECT=YES,LIST=YES
         END
