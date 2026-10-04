         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __fildef prologue
@@FILDEF PDPPRLG CINDEX=0,FRAME=1200,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __fildef code
         L     5,0(11)
         L     7,4(11)
         SLR   3,3
         LA    6,136(,13)
         LA    2,20(0,0)
         
*** MEMSET ***
         LR    14,6           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
         STC   2,136(13)
         MVI   137(13),1
         MVI   138(13),64
         LA    2,96(,13)
         ST    2,144(13)
         IC    2,0(5)
         LA    15,160(,13)
         LA    4,166(,13)
         CLM   2,1,=XL1'00'
         BE    @@L3
         ST    15,96(13)
         MVC   160(2,13),=H'1'
         MVC   162(2,13),=H'1'
         ST    5,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         STH   15,164(13)
         ST    4,88(13)
         ST    5,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         B     @@L4
@@L3     EQU   *
         L     12,0(,10)
         ST    15,96(13)
         MVC   160(2,13),=H'85'
         MVC   162(2,13),=H'1'
         MVC   164(2,13),=H'8'
         LA    2,8(0,0)
         
*** MEMSET ***
         LR    14,4           => target (s)
         LR    15,2           => length (n)
         SLR   0,0             => source (NULL)
         LR    1,3            fill character
         SLL   1,24            move fill to high byte
         MVCL  14,0            Set target to fill character
@@L4     EQU   *
         L     12,0(,10)
         LA    2,264(,13)
         ST    2,100(13)
         MVC   264(2,13),=H'2'
         MVC   266(2,13),=H'1'
         ST    7,88(13)
         LA    1,88(,13)
         L     15,=V(STRLEN)
         BALR  14,15
         STH   15,268(13)
         LA    2,270(,13)
         ST    2,88(13)
         ST    7,92(13)
         LA    1,88(,13)
         L     15,=V(STRCPY)
         BALR  14,15
         LA    2,368(,13)
         ST    2,104(13)
         MVC   368(2,13),=H'4'
         MVC   370(2,13),=H'1'
         MVC   372(2,13),=H'1'
         MVI   374(13),8
         MVC   108(4,13),=F'0'
         MVC   112(4,13),=F'0'
         MVC   116(4,13),=F'-2147483648'
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
         LTR   15,15
         BE    @@L6
         L     2,8(11)
         LTR   2,2
         BE    @@L7
         MVI   374(13),4
         L     2,12(11)
         LA    3,5(0,0)
         CLR   2,3
         BE    @@L7
         LA    2,472(,13)
         ST    2,108(13)
         MVC   472(2,13),=H'73'
         MVC   474(2,13),=H'1'
         MVC   476(2,13),=H'1'
         MVI   478(13),64
         LA    2,576(,13)
         ST    2,112(13)
         MVC   576(2,13),=H'66'
         MVC   578(2,13),=H'1'
         MVC   580(2,13),=H'2'
         MVI   582(13),0
         MVI   583(13),255
@@L7     EQU   *
         L     12,0(,10)
         ST    6,88(13)
         LA    1,88(,13)
         L     15,=V(@@SVC99)
         BALR  14,15
         LR    3,15
@@L6     EQU   *
         L     12,0(,10)
         LTR   3,3
         BE    @@L12
         LH    2,140(13)
         CLM   2,3,=H'0'
         BE    @@L12
         LA    1,88(,13)
         L     15,=V(@@ERRNO)
         BALR  14,15
         LH    2,140(13)
         SLL   2,16
         SRA   2,16
         ST    2,0(15)
@@L12    EQU   *
         L     12,0(,10)
         IC    2,0(5)
         CLM   2,1,=XL1'00'
         BNE   @@L13
         LTR   3,3
         BNE   @@L13
         LH    2,160(13)
         CLM   2,3,=H'85'
         BNE   @@L13
         MVC   0(8,5),166(13)
         STC   3,8(5)
@@L13    EQU   *
         L     12,0(,10)
         LR    15,3
* Function __fildef epilogue
         PDPEPIL
* Function __fildef literal pool
         DS    0F
         LTORG
* Function __fildef page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
