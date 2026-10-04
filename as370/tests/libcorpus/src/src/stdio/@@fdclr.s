         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fdclr prologue
@@FDCLR  PDPPRLG CINDEX=0,FRAME=1200,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fdclr code
         L     5,0(11)
         LA    4,136(,13)
         SLR   3,3
         LA    2,20(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         STC   2,136(13)
         MVI   137(13),2
         LA    2,96(,13)
         ST    2,144(13)
         LA    2,160(,13)
         ST    2,96(13)
         MVC   160(2,13),=H'1'
         MVC   162(2,13),=H'1'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         STH   15,164(13)
         LA    2,166(,13)
         ST    2,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         MVC   100(4,13),=F'-2147483648'
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
* Function __fdclr epilogue
         PDPEPIL
* Function __fdclr literal pool
         DS    0F
         LTORG
* Function __fdclr page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
