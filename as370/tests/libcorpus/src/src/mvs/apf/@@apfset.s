         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'clib_apf_setup'
* Program text area
         DS    0F
* X-func *@@APFSET prologue
@@APFSET PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@APFSET code
         SLR   3,3
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         L     2,=F'-1'
         LTR   15,15
         BE    @@L1
         IC    2,268(15)
         N     2,=F'1'
         LTR   2,2
         BNE   @@L3
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=A(@@F6)
         BALR  14,15
         LR    3,15
@@L3     EQU   *
         L     12,0(,10)
         LR    2,3
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@APFSET epilogue
         PDPEPIL
* Function *@@APFSET literal pool
         DS    0F
         LTORG
* Function *@@APFSET page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         
&FUNC    SETC 'unauth_setup'
         DS    0F
* Function unauth_setup,F6 prologue
@@F6     PDPPRLG CINDEX=1,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN1
         LTORG
@@FEN1   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG1    EQU   *
         LR    11,1
         L     10,=A(@@PGT1)
* Function unauth_setup code
         L     4,0(11)
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         L     15,=F'-1'
         LTR   3,3
         BE    @@L4
         LA    1,88(,13)
         L     15,=V(@@AUTASK)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         IC    2,269(3)
         SLL   2,24
         SRA   2,24
         C     2,=F'0'
         BNL   @@L7
         LA    1,88(,13)
         L     15,=V(@@AUSTEP)
         BALR  14,15
         LTR   15,15
         BNE   @@L4
         IC    2,269(3)
         N     2,=F'64'
         LTR   2,2
         BE    @@L4
@@L7     EQU   *
         L     12,0(,10)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=A(@@F7)
         BALR  14,15
@@L4     EQU   *
         L     12,0(,10)
* Function unauth_setup epilogue
         PDPEPIL
* Function unauth_setup literal pool
         DS    0F
         LTORG
* Function unauth_setup page table
         DS    0F
@@PGT1   EQU   *
         DC    A(@@PG1)
         
&FUNC    SETC 'auth_pgm'
@@LC0    EQU   *
         DC    C'CTHREAD'
         DC    X'0'
         DS    0F
* Function auth_pgm,F7 prologue
@@F7     PDPPRLG CINDEX=2,FRAME=96,BASER=12,ENTRY=NO
         B     @@FEN2
         LTORG
@@FEN2   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG2    EQU   *
         LR    11,1
         L     10,=A(@@PGT2)
* Function auth_pgm code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(@@AUTNAM)
         BALR  14,15
         LA    1,88(,13)
         L     15,=V(@@IDECTH)
         BALR  14,15
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(@@AUTNAM)
         BALR  14,15
* Function auth_pgm epilogue
         PDPEPIL
* Function auth_pgm literal pool
         DS    0F
         LTORG
* Function auth_pgm page table
         DS    0F
@@PGT2   EQU   *
         DC    A(@@PG2)
         END
