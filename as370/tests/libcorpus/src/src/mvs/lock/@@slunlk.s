         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'sysunlock'
* Program text area
@@LC0    EQU   *
         DC    C'G.LOCK.%08X'
         DC    X'0'
@@LC1    EQU   *
         DC    C'CSYSLOCK'
         DC    X'0'
         DS    0F
* X-func *@@SLUNLK prologue
@@SLUNLK PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SLUNLK code
         LA    3,1(0,0)
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
         ST    3,100(13)
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function *@@SLUNLK epilogue
         PDPEPIL
* Function *@@SLUNLK literal pool
         DS    0F
         LTORG
* Function *@@SLUNLK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
