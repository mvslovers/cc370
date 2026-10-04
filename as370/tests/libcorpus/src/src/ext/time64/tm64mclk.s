         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'mclock64'
* Program text area
         DS    0F
* X-func *TM64MCLK prologue
TM64MCLK PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64MCLK code
         LR    6,0
         LA    2,104(13) get address of 8 byte work area
         STCK  0(2) store clock into work area
         
         L     4,104(13)
         L     5,4+104(13)
         LR    3,5
         A     3,=F'905969664'
         LA    15,1(0,0)
         CLR   3,5
         BL    @@L2
         SLR   15,15
@@L2     EQU   *
         L     12,0(,10)
         LR    2,4
         A     2,=F'-2106655884'
         AR    2,15
         SRDL  2,12
         ST    2,104(13)
         ST    3,4+104(13)
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'1000'
         ST    2,96(13)
         LA    1,88(,13)
         L     15,=V(@@64DU32)
         BALR  14,15
         MVC   0(8,6),104(13)
         LR    15,6
* Function *TM64MCLK epilogue
         PDPEPIL
* Function *TM64MCLK literal pool
         DS    0F
         LTORG
* Function *TM64MCLK page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
