         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_lock'
* Program text area
@@LC0    EQU   *
         DC    C'CTHDX.%04X.%08X'
         DC    X'0'
@@LC1    EQU   *
         DC    C'LCTHREAD'
         DC    X'0'
         DS    0F
* X-func *@@CTLOCK prologue
@@CTLOCK PDPPRLG CINDEX=0,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTLOCK code
         L     5,0(11)
         L     3,4(11)
         LTR   3,3
         BNE   @@L2
         L     4,540(3)
         L     2,548(3)
         LH    2,36(2)
         N     2,=XL4'0000FFFF'
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    2,96(13)
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L2     EQU   *
         L     12,0(,10)
         LTR   5,5
         BE    @@L3
         LA    5,4(0,0)
@@L3     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC1)
         ST    3,92(13)
         ST    5,96(13)
         MVC   100(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function *@@CTLOCK epilogue
         PDPEPIL
* Function *@@CTLOCK literal pool
         DS    0F
         LTORG
* Function *@@CTLOCK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'cthread_unlock'
         DS    0F
* X-func *@@CTUNLK prologue
@@CTUNLK PDPPRLG CINDEX=1,FRAME=128,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function *@@CTUNLK code
         L     3,0(11)
         LTR   3,3
         BNE   @@L5
         L     4,540(3)
         L     2,548(3)
         LH    2,36(2)
         N     2,=XL4'0000FFFF'
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=A(@@LC0)
         ST    2,96(13)
         ST    4,100(13)
         LA    1,88(,13)
         L     15,=V(SPRINTF)
         BALR  14,15
@@L5     EQU   *
         L     12,0(,10)
         MVC   88(4,13),=A(@@LC1)
         ST    3,92(13)
         MVC   96(4,13),=F'0'
         MVC   100(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(@@ENQDEQ)
         BALR  14,15
* Function *@@CTUNLK epilogue
         PDPEPIL
* Function *@@CTUNLK literal pool
         DS    0F
         LTORG
* Function *@@CTUNLK page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
