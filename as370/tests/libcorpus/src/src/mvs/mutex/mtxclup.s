         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cleanup_mutex'
* Program text area
@@LC0    EQU   *
         DC    C'MUTEX.%08X'
         DC    X'0'
         DS    0F
* Function cleanup_mutex,F1 prologue
@@F1     PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=NO
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function cleanup_mutex code
         L     2,0(11)
         ST    2,88(13)
         LA    1,88(,13)
         L     15,=V(MTXHELD)
         BALR  14,15
         LTR   15,15
         BE    @@L1
         MVC   0(4,2),=F'0'
         MVC   4(4,2),=F'0'
         MVC   88(4,13),=A(@@LC0)
         MVC   92(4,13),=F'0'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@LKRNUF)
         BALR  14,15
@@L1     EQU   *
         L     12,0(,10)
* Function cleanup_mutex epilogue
         PDPEPIL
* Function cleanup_mutex literal pool
         DS    0F
         LTORG
* Function cleanup_mutex page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DS    0F
* X-func mtxclup prologue
MTXCLUP  PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function mtxclup code
         L     15,0(11)
         LTR   15,15
         BE    @@L3
         MVC   88(4,13),=A(@@F1)
         ST    15,92(13)
         LA    1,88(,13)
         L     15,=V(@@@TRY)
         BALR  14,15
@@L3     EQU   *
         L     12,0(,10)
* Function mtxclup epilogue
         PDPEPIL
* Function mtxclup literal pool
         DS    0F
         LTORG
* Function mtxclup page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         END
