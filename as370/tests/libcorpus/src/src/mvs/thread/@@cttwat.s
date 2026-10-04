         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'cthread_timed_wait'
* Program text area
         DS    0F
* X-func *@@CTTWAT prologue
@@CTTWAT PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@CTTWAT code
         L     3,0(11)
         MVC   104(4,13),=F'0'
         LTR   3,3
         BE    @@L3
         ST    3,88(13)
         MVC   92(4,13),4(11)
         MVC   96(4,13),8(11)
         LA    1,88(,13)
         L     15,=V(@@ECBTW)
         BALR  14,15
         L     2,0(3)
         N     2,=F'1073741823'
         ST    2,104(13)
         MVC   0(4,3),=F'0'
@@L3     EQU   *
         L     12,0(,10)
         L     15,104(13)
* Function *@@CTTWAT epilogue
         PDPEPIL
* Function *@@CTTWAT literal pool
         DS    0F
         LTORG
* Function *@@CTTWAT page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
