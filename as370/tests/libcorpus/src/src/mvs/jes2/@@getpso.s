         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
* X-func __getpso prologue
@@GETPSO PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function __getpso code
         MVC   88(4,13),=F'0'
         LA    2,88(,13)
         L     15,PSATOLD-PSA          OUR TCB ADDRESS
         L     15,TCBJSCB-TCB(,15)     JSCB ADDRESS
         USING IEZJSCB,15
         L     15,JSCBACT              ACTIVE JSCB ADDRESS
         L     15,JSCBSSIB             SSIB ADDRESS
         DROP  15
         L     15,SSIBSUSE-SSIB(,15)   SJB ADDRESS
         L     15,SJBPSOP-SJBDSECT(,15) PSO ADDRESS
         ST    15,0(,2)
         L     15,88(13)
* Function __getpso epilogue
         PDPEPIL
* Function __getpso literal pool
         DS    0F
         LTORG
* Function __getpso page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         PRINT NOGEN
         IEFJSSOB (SO),CONTIG=NO
         CSECT ,
         $TQE
         $CMB
         $PSO
         $SJB
         $PDDB
         IEZJSCB
         IEFJSSIB
         IKJTCB
         IHAPSA
         END
