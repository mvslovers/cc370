* T' eines SYMBOLS -- Referenz, die as370 heute NICHT besteht.
*
* Gemessen gegen IFOX00 (Listing in tests/listref/): alle 18 Faelle
* antworten OK.  as370 besteht drei.
*
*   DS/DC Typ F H C X D P ...   dieser Buchstabe, DS 0H bleibt 'H'
*   Label auf einem Befehl      'I'
*   CSECT- oder DSECT-Name      'J'
*   EXTRN                       'T'
*   EQU, absolut ODER reloz.    'U'
*   undefiniert                 'U'
*
* NICHT in run.sh verdrahtet: as370 faellt durch, und die Ursache ist
* nicht ein fehlendes Feld, sondern die Reihenfolge der Phasen --
* macro_pass() expandiert ALLE Makros, bevor prescan_literals und
* do_pass(1) laufen, also bevor ein einziges Symbol existiert.  Ein
* AIF ueber T'SYMBOL wird entschieden, wenn die Symboltabelle noch
* leer ist.  Siehe Issue #144.
*
* Der Unterschied zu #142: dort haengt die Antwort nur am TEXT des
* Arguments (X'C0D' ist ohne Symboltabelle als selbstdefinierter Term
* erkennbar), deshalb war sie in macro_pass beantwortbar.
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
