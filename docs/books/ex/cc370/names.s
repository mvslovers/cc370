         COPY  PDPTOP
         CSECT
* X-var record_count
         ENTRY RECORD@C
* Program data area
         DS    0F
RECORD@C EQU   *
         DC    F'0'
* Program text area
         DS    0F
* X-func copy_file prologue
COPY@FIL PDPPRLG CINDEX=0,FRAME=96,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function copy_file code
         MVC   88(4,13),0(11)
         LA    1,88(,13)
         L     15,=V(OPEN@INP)
         BALR  14,15
         LR    4,15
         ST    15,88(13)
         LA    1,88(,13)
         L     15,=V(TRACE)
         BALR  14,15
         L     3,=A(RECORD@C)
         L     2,0(3)
         A     2,=F'1'
         ST    2,0(3)
         ST    4,88(13)
         LA    1,88(,13)
         L     15,=V(WRITEREC)
         BALR  14,15
* Function copy_file epilogue
         PDPEPIL
* Function copy_file literal pool
         DS    0F
         LTORG
* Function copy_file page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
