         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'SELECT  '
         DC    X'0'
         DS    0F
* X-func *@@ISPSEL prologue
@@ISPSEL PDPPRLG CINDEX=0,FRAME=368,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@ISPSEL code
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),0(11)
         LA    3,4(,11)
         ST    3,96(13)
         LA    1,88(,13)
         L     15,=V(VSPRINTF)
         BALR  14,15
         ST    15,360(13)
         MVC   88(4,13),=A(@@LC0)
         LA    3,360(,13)
         ST    3,92(13)
         O     2,=F'-2147483648'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@ISPLNK)
         BALR  14,15
* Function *@@ISPSEL epilogue
         PDPEPIL
* Function *@@ISPSEL literal pool
         DS    0F
         LTORG
* Function *@@ISPSEL page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
