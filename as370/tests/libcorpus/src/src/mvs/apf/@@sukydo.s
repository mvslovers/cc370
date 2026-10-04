         COPY  PDPTOP
         CSECT
         
&FUNC    SETC 'super_key_do'
* Program text area
         DS    0F
* X-func *@@SUKYDO prologue
@@SUKYDO PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *@@SUKYDO code
         MVC   89(1,13),3(11)
         LA    6,8(,11)
         LA    1,88(,13)
         L     15,=V(@@ISSUP)
         BALR  14,15
         LR    5,15
         LTR   15,15
         BNE   @@L2
         MODESET MODE=SUP      switch to supervisor state
         LR    3,15              save return code
         LTR   3,3
         BNE   @@L4
@@L2     EQU   *
         L     12,0(,10)
         LA    4,88(,13)
         IPK   0             get psw key in R2
         STC   2,0(,4)      save psw key
         IC    2,89(13)
         CLM   2,1,=XL1'FF'
         BE    @@L5
         CLM   2,1,=XL1'0F'
         BH    @@L6
         SLL   2,4
         STC   2,89(13)
@@L6     EQU   *
         L     12,0(,10)
         LA    3,89(,13)
         IC    2,0(,3)           get new psw key
         SPKA  0(2)             save in psw
@@L5     EQU   *
         L     12,0(,10)
         L     2,4(11)
         LR    15,2          => function to call 
         LR    1,6           => parameter list
         BALR  14,15         call function
         LR    3,15          save return code
         IC    2,0(,4)           get prev psw key
         SPKA  0(2)             save in psw
         LTR   5,5
         BNE   @@L4
         MODESET MODE=PROB     switch to problem state
@@L4     EQU   *
         L     12,0(,10)
         LR    15,3
* Function *@@SUKYDO epilogue
         PDPEPIL
* Function *@@SUKYDO literal pool
         DS    0F
         LTORG
* Function *@@SUKYDO page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
