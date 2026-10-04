         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __inc prologue
@@INC    PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __inc code
         L     15,0(11)
         MVC   88(4,13),=F'0'
         LTR   15,15
         BE    @@L3
         
@@INCAGN DS    0H
         L     0,0(,15)    get current value
         LR    1,0         copy for new value
         C     1,=F'2147483647'  max value?
         BNE   @@INCIT       no, bump it up
         SR    1,1         reset to zero
         B     @@INCSWP
@@INCIT  DS    0H
         A     1,=F'1'     increment new value
@@INCSWP DS    0H
         CS    0,1,0(15)   save new value in memory
         BNZ   @@INCAGN       changed, try again
         ST    0,88(13)        return value
@@L3     EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function __inc epilogue
         PDPEPIL
* Function __inc literal pool
         DS    0F
         LTORG
* Function __inc page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
