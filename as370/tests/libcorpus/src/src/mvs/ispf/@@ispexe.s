         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'ISPEXEC'
         DC    X'0'
         DS    0F
* X-func *@@ISPEXE prologue
@@ISPEXE PDPPRLG CINDEX=0,FRAME=360,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ISPEXE code
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),0(11)
         LA    2,4(,11)
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(VSPRINTF)
         BALR  14,15
         MVC   88(4,13),=A(@@LC0)
         ST    3,92(13)
         LA    1,88(,13)
         L     15,=V(TSOCMDF)
         BALR  14,15
* Function *@@ISPEXE epilogue
         PDPEPIL
* Function *@@ISPEXE literal pool
         DS    0F
         LTORG
* Function *@@ISPEXE page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
