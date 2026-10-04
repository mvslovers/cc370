         COPY  PDPTOP
         CSECT
* Program text area
@@LC0    EQU   *
         DC    X'0'
         DS    XL7
         DS    0F
* X-func __jsrd4 prologue
@@JSRD4  PDPPRLG CINDEX=0,FRAME=144,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __jsrd4 code
         L     15,0(11)
         L     7,4(11)
         L     8,8(11)
         L     6,12(11)
         MVC   136(4,13),=F'-1'
         MVC   124(4,13),=F'0'
         MVC   120(4,13),=F'0'
         LA    4,88(,13)
         LA    5,32(0,0)
         SLR   2,2
         LR    3,2
         MVCL  4,2
         L     2,=A(@@LC0)
         MVC   128(8,13),0(2)
         LTR   15,15
         BE    @@L3
         L     2,16(15)
         LTR   2,2
         BE    @@L3
         STH   6,62(2)
         L     5,20(15)
         LA    4,120(,13)
         LA    3,124(,13)
         LA    2,128(,13)
         XC    0(8,2),0(2)  Initialize MBBCCHHR to zero
         LR    1,7           Load MTTR value
         STC   1,7(2)       Save R value
         SRL   1,8           Shift TT value
         N     1,=F'65535'     Keep just the TT value
         SR    0,0            Prepare for divide
         DR    0,5           Divide by trks per cyl
         ST    0,0(,4)       Store head number
         ST    1,0(,3)       Store cylinder number
         MVC   3(2,2),2(3)  Copy cylinder number
         MVC   5(2,2),2(4)  Copy head number
         MVC   136(4,13),=F'0'
         L     5,16(15)
         LA    4,88(,13)
         LA    3,128(,13)
         LA    2,136(,13)
         USING IHADCB,5      ADDRESSING FOR DCB DSECT
         MVC   DCBSYNAD+1(3),=AL3(SYNAD)  SET SYNAD ADDR IN DCB
         DROP  5             DROP ADDRESSING FOR DCB
         LR    10,2            R10 => rc
         READ  (4),DI,(5),(8),(6),,(3),MF=E
         CHECK (4)
         B     QUIT
         
SYNAD    SYNADAF ACSMETH=BDAM DECODE ERROR CAUSE
         L     1,128(,1)      Get DECB address
         L     0,0(,1)        Get DECB ECB value
         ST    0,0(,10)       Save ECB value as return code
         SYNADRLS ,           RELEASE WORK AREA
         BR    14             RETURN TO OP SYS
QUIT     DS    0H
@@L3     EQU   *
         L     12,0(,10)
         L     15,136(13)
* Function __jsrd4 epilogue
         PDPEPIL
* Function __jsrd4 literal pool
         DS    0F
         LTORG
* Function __jsrd4 page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         DCBD  DSORG=DA,DEVD=DA
         CSECT ,
         END
