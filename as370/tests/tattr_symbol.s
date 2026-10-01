         MACRO
         CKT   &CC,&EXP
         AIF   (T'&CC EQ '&EXP').OK
         DC    C'BAD'
         MEXIT
.OK      ANOP
         DC    C'OK '
         MEND
TSECT    CSECT
SF       DS    F
SH       DS    H
SC       DS    CL3
SX       DS    XL2
SD       DS    D
SP       DS    PL2
SZ       DS    0H
DF       DC    F'1'
DC1      DC    C'AB'
LAB      LA    1,0
EQA      EQU   5
EQR      EQU   SF
         EXTRN EXT1
DSECTN   DSECT
DSF      DS    F
TSECT    CSECT
         CKT   SF,F
         CKT   SH,H
         CKT   SC,C
         CKT   SX,X
         CKT   SD,D
         CKT   SP,P
         CKT   SZ,H
         CKT   DF,F
         CKT   DC1,C
         CKT   LAB,I
         CKT   EQA,U
         CKT   EQR,U
         CKT   EXT1,T
         CKT   TSECT,J
         CKT   DSECTN,J
         CKT   DSF,F
         CKT   NOSUCH,U
         END
