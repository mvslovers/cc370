         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    X'0'
         DS    0F
* X-func putenv prologue
PUTENV   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function putenv code
         L     3,0(11)
         ST    3,88(13)
         MVC   92(4,13),=F'126'
         LA    1,88(,13)
         L     15,=V(STRCHR)
         BALR  14,15
         LR    2,15
         L     15,=A(@@LC0)
         LTR   2,2
         BE    @@L3
         MVI   0(2),0
         LR    15,2
         A     15,=F'1'
@@L3     EQU   *
         L     12,0(,10)
         ST    3,88(13)
         ST    15,92(13)
         MVC   96(4,13),=F'1'
         LA    1,88(,13)
         L     15,=V(SETENV)
         BALR  14,15
         LTR   2,2
         BE    @@L5
         MVI   0(2),126
@@L5     EQU   *
         L     12,0(,10)
* Function putenv epilogue
         PDPEPIL
* Function putenv literal pool
         DS    0F
         LTORG
* Function putenv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
