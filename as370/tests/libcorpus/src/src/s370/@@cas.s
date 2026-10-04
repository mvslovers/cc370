         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __cas prologue
@@CAS    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __cas code
         L     2,0(11)
         L     15,4(11)
         L     3,8(11)
         MVC   88(4,13),=F'-1'
         LTR   2,2
         BE    @@L4
         LTR   15,15
         BE    @@L4
         
         L     0,0(,15)    expected value
         LR    1,3        new value
         CS    0,1,0(2)   swap it in if *mem is still the expected one
         BC    8,@@CASOK   CC=0: it was, and it is ours now
         ST    0,0(,15)    CC=1: hand back what is there instead
         LA    1,1
         ST    1,88(13)        rc = 1, not swapped
         B     @@CASX
@@CASOK  SR    1,1
         ST    1,88(13)        rc = 0, swapped
@@CASX   DS    0H
@@L4     EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function __cas epilogue
         PDPEPIL
* Function __cas literal pool
         DS    0F
         LTORG
* Function __cas page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
