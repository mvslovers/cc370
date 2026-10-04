         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'tmr_secs'
* Program text area
         DS    0F
* X-func *@@TMSECS prologue
@@TMSECS PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@TMSECS code
         L     15,0(11)
         LTR   15,15
         BNE   @@L2
         LA    15,88(,13)
@@L2     EQU   *
         L     12,0(,10)
         LA    6,96(,13)
         STCK  0(6)
         L     4,96(13)
         L     5,4+96(13)
         LR    3,5
         A     3,=F'905969664'
         LA    7,1(0,0)
         CLR   3,5
         BL    @@L3
         SLR   7,7
@@L3     EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'-2106655884'
         AR    2,7
         SRDL  2,12
         ST    2,96(13)
         ST    3,4+96(13)
         LA    2,104(,13)
         LM    0,1,0(6)       load TOD microseconds
         D     0,=F'1000000'  divide by 1000000
         ST    1,0(0,2)       store seconds (quotient)
         ST    0,4(0,2)       store microseconds (remainder)
         L     2,104(13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    0,80(,13)
         SD    0,=XL8'4E00000080000000'
         L     2,108(13)
         MVC   80(4,13),=XL4'4E000000'
         ST    2,84(,13)
         XI    84(13),128
         LD    2,80(,13)
         SD    2,=XL8'4E00000080000000'
         DD    2,=D'1.0E+6'
         ADR   0,2
         STD   0,0(15)
@@L4     EQU   *
* Function *@@TMSECS epilogue
         PDPEPIL
* Function *@@TMSECS literal pool
         DS    0F
         LTORG
* Function *@@TMSECS page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
