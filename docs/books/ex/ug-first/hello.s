         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    C'Hello, MVS!'
         DC    X'0'
         DS    0F
         DC    C'CC370',AL1(1,4,0)
         EXTRN @@CRT0
         ENTRY @@MAIN
@@MAIN   DS    0H
         BALR  15,0
         USING *,15
         L     15,=V(@@CRT0)
         BR    15
         DROP  15
         LTORG
* X-func main prologue
MAIN     PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function main code
         MVC   88(4,13),=A(@@LC0)
         LA    1,88(,13)
         L     15,=V(PUTS)
         BALR  14,15
         SLR   15,15
* Function main epilogue
         PDPEPIL
* Function main literal pool
         DS    0F
         LTORG
* Function main page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END   @@MAIN
