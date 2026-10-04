         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __swap prologue
@@SWAP   PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __swap code
         L     15,0(11)
         L     2,4(11)
         MVC   88(4,13),=F'0'
         LTR   15,15
         BE    @@L3
         
@@SWPAGN DS    0H
         L     0,0(,15)    get current value
         LR    1,2        get new value
         CS    0,1,0(15)   save new value in memory
         BNZ   @@SWPAGN    changed under us, try again
         ST    0,88(13)        return the value we replaced
@@L3     EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function __swap epilogue
         PDPEPIL
* Function __swap literal pool
         DS    0F
         LTORG
* Function __swap page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
