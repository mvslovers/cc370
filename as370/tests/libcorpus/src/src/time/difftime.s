         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func difftime prologue
DIFFTIME PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function difftime code
         L     2,0(11)
         S     2,4(11)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         LTR   2,2
         BNL   @@L2
         AD    0,=D'4.294967296E+9'
@@L2     EQU   *
         L     12,0(,10)
* Function difftime epilogue
         PDPEPIL
* Function difftime literal pool
         DS    0F
         LTORG
* Function difftime page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
