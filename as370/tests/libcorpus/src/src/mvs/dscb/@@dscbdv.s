         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __dscbdv prologue
@@DSCBDV PDPPRLG CINDEX=0,FRAME=176,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __dscbdv code
         LA    3,104(,13)
         ST    3,88(13)
         MVC   92(4,13),=F'44'
         MVC   96(4,13),0(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVI   148(13),0
         LA    2,152(,13)
         ST    2,88(13)
         MVC   92(4,13),=F'6'
         MVC   96(4,13),4(11)
         MVC   100(4,13),=F'64'
         LA    1,88(,13)
         L     15,=V(STRCPYP)
         BALR  14,15
         MVI   158(13),0
         MVC   160(4,13),=F'-1056964608'
         ST    3,164(13)
         ST    2,168(13)
         MVC   172(4,13),8(11)
         LA    2,160(,13)
         LR    1,2
         SVC   27
         LR    2,15
         LR    15,2
* Function __dscbdv epilogue
         PDPEPIL
* Function __dscbdv literal pool
         DS    0F
         LTORG
* Function __dscbdv page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         LOCATE    INDAB  READ CATALOG ENTRY FOR DATA SET A.B
*                          INTO VIRTUAL STORAGE AREA NAMED LOCAREA.
*                          LOCAREA MAY ALSO CONTAIN A 3-BYTE
*                          TTR OR A 6-BYTE SERIAL NUMBER
INDAB     CAMLST    NAME,AB,,LOCAREA
AB        DC        CL44'A.B'
LOCAREA   DS        0D
          DS        265C

         END
