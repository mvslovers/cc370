         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssct_new'
* Program text area
@@LC0    EQU   *
         DC    C'SSCT'
         DC    X'0'
         DS    0F
* X-func *@@SSNEW prologue
@@SSNEW  PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SSNEW code
         L     5,0(11)
         SLR   6,6
         IPK   0             get psw key in R2
         LR    4,2           save psw key in register
         CLM   4,1,=XL1'00'
         BE    @@L2
         LA    6,1(0,0)
         SLR   2,2               PSW key 0 value
         SPKA  0(2)             save in psw
@@L2     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=F'24'
         MVC   92(4,13),=F'241'
         LA    1,88(,13)
         L     15,=V(GETMAIN)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L3
         L     2,=A(@@LC0)
         MVC   0(4,15),0(2)
         LTR   5,5
         BE    @@L4
         A     3,=F'8'
         ST    3,88(13)
         A     3,=F'-8'
         MVC   92(4,13),=F'4'
         ST    5,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         MVC   16(4,3),4(11)
         MVC   20(4,3),8(11)
@@L3     EQU   *
         L     12,0(,10)
         LTR   6,6
         BE    @@L5
         LR    2,4               get prev psw key
         SPKA  0(2)             save in psw
@@L5     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@SSNEW epilogue
         PDPEPIL
* Function *@@SSNEW literal pool
         DS    0F
         LTORG
* Function *@@SSNEW page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
