         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'__xmpost'
         DC    X'0'
@@LC0    EQU   *
         DC    C'%s missing ASCB'
         DC    X'0'
@@LC1    EQU   *
         DC    C'%s missing ECB'
         DC    X'0'
         DS    0F
* X-func __xmpost prologue
@@XMPOST PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __xmpost code
         L     3,0(11)
         L     15,4(11)
         LTR   3,3
         BNE   @@L2
         MVC   88(4,13),=A(@@LC0)
         B     @@L4
@@L2     EQU   *
         L     12,0(,10)
         LTR   15,15
         BNE   @@L3
         MVC   88(4,13),=A(@@LC1)
@@L4     EQU   *
         L     12,0(,10)
         MVC   92(4,13),=A(@V1)
         LA    1,88(,13)
         L     15,=V(WTOF)
         BALR  14,15
         B     @@L1
@@L3     EQU   *
         L     12,0(,10)
         O     15,=F'-2147483648'
         L     2,8(11)
         O     2,=F'1073741824'
         N     2,=F'2147483647'
         DS    0H
         STM   14,12,12(13)    save registers
         LR    9,13            only register preserved after XM POST
         LR    10,2           POST COMPLETION CODE
         LR    11,15           ECB ADDRESS
         LA    12,POSTERR      ERROR ROUTINE
         LR    13,3           ASCB ADDRESS
         L     15,CVTPTR       CVT ADDRESS
         L     15,CVT0PT01-CVTMAP(,15)   POST BRANCH-ENTRY
         BALR  14,15
         LR    13,9            restore save area pointer
         LM    14,12,12(13)    restore registers
         B     DONE
POSTERR  DS    0H
         BR    14
DONE     DS    0H
@@L1     EQU   *
         L     12,0(,10)
* Function __xmpost epilogue
         PDPEPIL
* Function __xmpost literal pool
         DS    0F
         LTORG
* Function __xmpost page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         IHAPSA ,
         CVT DSECT=YES,LIST=YES
         END
