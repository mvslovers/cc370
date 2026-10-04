         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__64_and'
* Program text area
         DS    0F
* X-func *@@64AND prologue
@@64AND  PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@64AND code
         L     2,0(11)
         L     4,4(11)
         L     15,8(11)
         LTR   2,2
         BE    @@L1
         LTR   4,4
         BE    @@L1
         LTR   15,15
         BE    @@L1
         L     3,4+0(2)
         L     2,0(2)
         L     5,4+0(4)
         L     4,0(4)
         NR    2,4
         NR    3,5
         ST    2,0(15)
         ST    3,4+0(15)
@@L1     EQU   *
         L     12,0(,10)
* Function *@@64AND epilogue
         PDPEPIL
* Function *@@64AND literal pool
         DS    0F
         LTORG
* Function *@@64AND page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
