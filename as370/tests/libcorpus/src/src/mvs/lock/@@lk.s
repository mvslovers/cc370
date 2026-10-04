         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'lock'
* Program text area
@@LC0    EQU   *
         DC    C'LOCK.%08X'
         DC    X'0'
@@LC1    EQU   *
         DC    C'CLIBLOCK'
         DC    X'0'
         DS    0F
* X-func *@@LK prologue
@@LK     PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@LK code
         L     3,4(11)
         LPR   2,3
         LCR   2,2
         SRL   2,31
         SLL   2,2
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC0)
         MVC   96(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC1)
         ST    3,92(13)
         ST    2,96(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function *@@LK epilogue
         PDPEPIL
* Function *@@LK literal pool
         DS    0F
         LTORG
* Function *@@LK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
