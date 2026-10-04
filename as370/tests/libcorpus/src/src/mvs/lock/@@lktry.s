         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'trylock'
* Program text area
@@LC0    EQU   *
         DC    C'LOCK.%08X'
         DC    X'0'
@@LC1    EQU   *
         DC    C'CLIBLOCK'
         DC    X'0'
         DS    0F
* X-func *@@LKTRY prologue
@@LKTRY  PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@LKTRY code
         LA    3,64(0,0)
         L     2,4(11)
         LTR   2,2
         BE    @@L2
         LA    3,68(0,0)
@@L2     EQU   *
         L     12,0(,10)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=A(@@LC0)
         MVC   96(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC1)
         ST    2,92(13)
         ST    3,96(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function *@@LKTRY epilogue
         PDPEPIL
* Function *@@LKTRY literal pool
         DS    0F
         LTORG
* Function *@@LKTRY page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
