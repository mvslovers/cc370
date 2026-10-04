         COPY  PDPTOP
         CSECT
* Program text area
@V1      EQU   *
         DC    C'LIBC370 2.1.0 (99f29bb-dirty)'
         DC    X'0'
         
&FUNC    SETC 'libc370_version'
         DS    0F
* X-func libc370_version prologue
LIBC370@ PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function libc370_version code
         L     15,=A(@V1)
* Function libc370_version epilogue
         PDPEPIL
* Function libc370_version literal pool
         DS    0F
         LTORG
* Function libc370_version page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
