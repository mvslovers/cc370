         COPY  PDPTOP
         CSECT
         
&FUNC    SETC '__austep'
* Program text area
         DS    0F
* X-func __austep prologue
@@AUSTEP PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __austep code
         LA    1,88(,13)
         L     15,=V(@@CRTGET)
         BALR  14,15
         LR    3,15
         MVC   88(4,13),=F'0'
         MVC   92(4,13),=F'0'
         TESTAUTH FCTN=1
         ST    15,88(13)
         L     2,88(13)
         LTR   2,2
         BNE   @@L3
         
         MODESET KEY=ZERO,MODE=SUP
         ICM   1,15,PSATOLD-PSA(0) Get our TCB address
         ICM   1,15,TCBJLB-TCB(1)  Get STEPLIB DCB
         LA    1,0(,1)             Purify DCB address
         ST    1,92(13)            Save STEPLIB DCB address
         LTR   14,1                Save DCB address
         BZ    QUITON              No STEPLIB
         USING IHADCB,1            DECLARE IT
         L     1,DCBDEBAD          LOAD DEB FOR STEPLIB
         N     1,=X'00FFFFFF'      FIX HIGH BYTE
         USING DEBBASIC,1
         TM    DEBFLGS1,DEBAPFIN   Is STEPLIB authorized?
         BNO   SETAPF              No, go set APF bit
         SR    1,1                 Yes, we're not changing STEPLIB
         ST    1,92(13)                No STEPLIB change
         B     QUITON
SETAPF   DS    0H
         OI    DEBFLGS1,DEBAPFIN   TURN ON APF LIBRARY BIT
         DROP  1
QUITON   DS    0H
         MODESET KEY=NZERO,MODE=PROB
         L     2,92(13)
         LTR   2,2
         BE    @@L3
         LTR   3,3
         BE    @@L3
         OI    269(3),64
@@L3     EQU   *
         L     12,0(,10)
         L     15,88(13)
* Function __austep epilogue
         PDPEPIL
* Function __austep literal pool
         DS    0F
         LTORG
* Function __austep page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         PRINT NOGEN
         IHAPSA ,            MAP LOW STORAGE
         CVT DSECT=YES
         IKJTCB DSECT=YES
         DCBD DSORG=PO,DEVD=DA
         IEZDEB
         PRINT GEN
         CSECT
         END
