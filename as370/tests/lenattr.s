* L' fragt nach der LAENGENANGABE des Symbols, K' nach der ZAHL DER
* ZEICHEN im Wert. as370 beantwortete beide mit strlen, also lieferte
* L' die Breite des Textes: L'&P mit &P = MINOR ergab 5, wo
* `MINOR DC CL8'..'' die Antwort 8 verlangt (cc370#244).
*
* SYS1.AMACLIB(ENQ) Zeile 169 rechnet `&LEN SETA L'&P(&RN)' und legt
* das Ergebnis in Zeile 170 als `DC AL1(&LEN)' direkt ins Objekt -
* ohne Verzweigung dazwischen. Zwoelf Module unterschieden sich in
* nichts anderem.
*
* Die bedingte Assemblierung laeuft waehrend der Makro-Expansion, also
* VOR beiden Durchgaengen: eine Symboltabelle gibt es dort nicht.
* IFOX00 verschraenkt beides und hat die Antwort einfach. Statt die
* Phasen umzustellen liest ein Vorablauf die Rohkarten einmal und
* merkt sich, welche Laengenangabe eine Marke auf DC/DS traegt.
*
* Er sieht nur offenen Code - eine im Makro erzeugte Marke steht nicht
* darin -, deshalb antwortet ein unbekanntes Symbol mit 1, dem Wert,
* den auch IFOX00 fuer ein unaufloesbares gibt.
*
* L1 bis L3 sind die Faelle. Die Kontrollen:
*
*   L4  L'EQ4      1, obwohl EQU 4 - IFOX00 meldet dazu IFO120
*   L5  L'NODEF    1, unbekannt - IFOX00 meldet IFO080
*   L6  K'&E       unveraendert die Zeichenzahl, nicht die Laenge
*   L7  L'FW       dasselbe ohne Variable, direkt als Symbol
*
* Punktzahl:  ohne Fix N4 N2 N7 Y1 Y1 YK NLIT
*             mit Fix  Y4 Y2 Y7 Y1 Y1 YK YLIT
         MACRO
         QL    &E,&T
         AIF   (L'&E EQ &T).A
         DC    C'N&T'
         MEXIT
.A       DC    C'Y&T'
         MEND
         MACRO
         QK    &E
         AIF   (K'&E EQ 5).B
         DC    C'NK'
         MEXIT
.B       DC    C'YK'
         MEND
LENATTR  CSECT
FW       DS    F
HW       DS    H
CH       DS    CL7
EQ4      EQU   4
         QL    FW,4
         QL    HW,2
         QL    CH,7
         QL    EQ4,1
         QL    NODEF,1
         QK    MINOR
         AIF   (L'FW EQ 4).C
         DC    C'NLIT'
         AGO   .D
.C       DC    C'YLIT'
.D       ANOP
         END
