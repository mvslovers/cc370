         COPY  PDPTOP
         CSECT
* Program text area
         DS    0F
@V1      EQU   *
         DC    F'0'
         DC    F'31'
         DC    F'59'
         DC    F'90'
         DC    F'120'
         DC    F'151'
         DC    F'181'
         DC    F'212'
         DC    F'243'
         DC    F'273'
         DC    F'304'
         DC    F'334'
         DC    F'0'
         DC    F'31'
         DC    F'60'
         DC    F'91'
         DC    F'121'
         DC    F'152'
         DC    F'182'
         DC    F'213'
         DC    F'244'
         DC    F'274'
         DC    F'305'
         DC    F'335'
         
&FUNC    SETC 'julian_days_by_month'
         DS    0F
* X-func *TM64JDBM prologue
TM64JDBM PDPPRLG CINDEX=0,FRAME=88,BASER=12,ENTRY=YES
         B     @@FEN0
         LTORG
@@FEN0   EQU   *
         DROP  12
         BALR  12,0
         USING *,12
@@PG0    EQU   *
         LR    11,1
         L     10,=A(@@PGT0)
* Function *TM64JDBM code
         L     2,0(11)
         SLL   2,1
         A     2,0(11)
         SLL   2,2
         A     2,4(11)
         SLL   2,2
         L     3,=A(@V1)
         L     15,0(2,3)
* Function *TM64JDBM epilogue
         PDPEPIL
* Function *TM64JDBM literal pool
         DS    0F
         LTORG
* Function *TM64JDBM page table
         DS    0F
@@PGT0   EQU   *
         DC    A(@@PG0)
         END
