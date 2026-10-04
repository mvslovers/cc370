         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'ssct_find'
* Program text area
         DS    0F
* X-func *@@SSFIND prologue
@@SSFIND PDPPRLG CINDEX=0,FRAME=112,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SSFIND code
         L     15,0(11)
         SLR   2,2
         L     2,16(2)
         L     2,296(2)
         L     3,24(2)
         LTR   15,15
         BE    @@L3
         IC    2,0(15)
         CLM   2,1,=XL1'00'
         BE    @@L3
         CLM   2,1,=XL1'40'
         BE    @@L3
         LA    4,104(,13)
         ST    4,88(13)
         MVC   92(4,13),=F'4'
         ST    15,96(13)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
@@L11    EQU   *
         LTR   3,3
         BE    @@L3
         CLC   8(4,3),0(4)
         LA    2,1(0,0)
         BH    *+12
         BL    *+6
         SLR   2,2
         LNR   2,2
         LTR   2,2
         BE    @@L3
         L     3,4(3)
         B     @@L11
@@L3     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@SSFIND epilogue
         PDPEPIL
* Function *@@SSFIND literal pool
         DS    0F
         LTORG
* Function *@@SSFIND page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
