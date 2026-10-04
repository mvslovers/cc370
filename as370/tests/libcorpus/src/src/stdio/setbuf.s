         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func setbuf prologue
SETBUF   PDPPRLG CINDEX=0,FRAME=104,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function setbuf code
         L     2,0(11)
         L     15,4(11)
         LTR   15,15
         BNE   @@L2
         ST    2,88(13)
         ST    15,92(13)
         MVC   96(4,13),=F'3'
         ST    15,100(13)
         B     @@L4
@@L2     EQU   *
         L     12,0(,10)
         ST    2,88(13)
         ST    15,92(13)
         MVC   96(4,13),=F'1'
         MVC   100(4,13),=F'32768'
@@L4     EQU   *
         L     12,0(,10)
         LA    1,88(,13)
         L     15,=V(SETVBUF)
         BALR  14,15
* Function setbuf epilogue
         PDPEPIL
* Function setbuf literal pool
         DS    0F
         LTORG
* Function setbuf page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
