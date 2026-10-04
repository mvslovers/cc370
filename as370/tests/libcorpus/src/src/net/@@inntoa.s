         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'0.0.0.0'
         DC    X'0'
         DS    XL8
         DS    0F
* X-func *@@INNTOA prologue
@@INNTOA PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@INNTOA code
         MVC   88(4,13),=A(@V1)
         MVC   92(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(@@WSAGET)
         BALR  14,15
         LR    2,15
         LTR   15,15
         BE    @@L1
         MVC   88(4,13),=F'2'
         ST    11,92(13)
         ST    15,96(13)
         MVC   100(4,13),=F'16'
         LA    1,88(,13)
         L     15,=V(@@INNTOP)
         BALR  14,15
         LR    2,15
@@L1     EQU   *
         L     12,0(,10)
         LR    15,2
* Function *@@INNTOA epilogue
         PDPEPIL
* Function *@@INNTOA literal pool
         DS    0F
         LTORG
* Function *@@INNTOA page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
