         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_from_i32'
* Program text area
         DS    0F
* X-func *@@64FI32 prologue
@@64FI32 PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64FI32 code
         L     15,0(11)
         L     2,4(11)
         LTR   15,15
         BE    @@L1
         MVC   0(4,15),=F'0'
         MVC   4(4,15),=F'0'
         LTR   2,2
         BNL   @@L3
         ST    15,88(13)
         LCR   2,2
         ST    2,92(13)
         ST    15,96(13)
         LA    1,88(,13)
         L     15,=V(@@64SU32)
         BALR  14,15
         B     @@L1
@@L3     EQU   *
         L     12,0(,10)
         ST    2,4(15)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64FI32 epilogue
         PDPEPIL
* Function *@@64FI32 literal pool
         DS    0F
         LTORG
* Function *@@64FI32 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
