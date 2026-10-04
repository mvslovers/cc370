         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __locate prologue
@@LOCATE PDPPRLG CINDEX=0,FRAME=168,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __locate code
         LA    2,104(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'44'
         MVC   96(4,13),0(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVI   148(13),0
         MVC   152(4,13),=F'1140850688'
         ST    2,156(13)
         MVC   160(4,13),=F'0'
         MVC   164(4,13),4(11)
         LA    2,152(,13)
         LR    1,2
         SVC   26
         LR    2,15
         LR    15,2
* Function __locate epilogue
         PDPEPIL
* Function __locate literal pool
         DS    0F
         LTORG
* Function __locate page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
