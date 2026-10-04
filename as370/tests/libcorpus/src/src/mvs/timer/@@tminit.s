         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_init'
* Program text area
@@LC0    EQU   *
         DC    C'**TMR**'
         DC    X'0'
         DS    0F
* X-func *@@TMINIT prologue
@@TMINIT PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMINIT code
         LA    1,88(,13)
         L     15,=V(@@TMRGET)
         BALR  14,15
         LR    3,15
         L     15,=F'-1'
         LTR   3,3
         BE    @@L1
         ST    3,88(13)
         MVC   92(4,13),=F'0'
         LA    1,88(,13)
         L     15,=V(@@LK)
         BALR  14,15
         LR    4,15
         IC    2,8(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BL    @@L3
         L     2,=A(@@LC0)
         MVC   0(8,3),0(2)
         LA    1,88(,13)
         L     15,=V(RAND)
         BALR  14,15
         SLL   15,8
         N     15,=F'16776960'
         ST    15,28(3)
         MVI   8(3),128
@@L3     EQU   *
         L     12,0(,10)
         LTR   4,4
         BNE   @@L4
         ST    3,88(13)
         ST    4,92(13)
         LA    1,88(,13)
         L     15,=V(@@LKUNLK)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
         SLR   15,15
@@L1     EQU   *
         L     12,0(,10)
* Function *@@TMINIT epilogue
         PDPEPIL
* Function *@@TMINIT literal pool
         DS    0F
         LTORG
* Function *@@TMINIT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
