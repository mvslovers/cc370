* T' ist ein Term eines SETC-Ausdrucks so gut wie eines Vergleichs.
* Nur der Vergleichspfad hatte ihn: `&T SETC T'&P' wies die vier
* Zeichen T'&P woertlich zu, und jedes Makro, das auf den zugewiesenen
* Wert verzweigt, ging falsch (cc370#257).
*
* Die ganze Maschinerie war schon da - der Vorablauf ueber offenen
* Code, is_selfdef, die Buchstabentabelle. Der Zeichenpfad erreichte
* sie nur nie. Jetzt eine Funktion, zwei Aufrufer.
*
* Die Buchstaben sind am Orakel gemessen:
*
*   DS F     F      DS H     H      DS CL7   C
*   DS D     D      DS XL2   X      DC A(0)  A
*   EQU 4    U      unbekannt U     3        N
*
* Die letzten drei sind die Kontrollen: ein EQU und ein unbekanntes
* Symbol geben beide U, und eine selbstdefinierende Zahl gibt N - wer
* nur die Typtabelle liest, faellt an der Zahl auf, wer nur auf
* Ziffern prueft, am EQU.
*
* Punktzahl:  ohne Fix neunmal E3 (der Buchstabe T selbst)
*             mit Fix  F H C D X U A U N
         MACRO
         QT    &P
         LCLC  &T
&T       SETC  T'&P
         DC    C'&T'
         MEND
SETCTYPE CSECT
FW       DS    F
HW       DS    H
CH       DS    CL7
DW       DS    D
XX       DS    XL2
EQ4      EQU   4
LAB      DC    A(0)
         QT    FW
         QT    HW
         QT    CH
         QT    DW
         QT    XX
         QT    EQ4
         QT    LAB
         QT    NODEF
         QT    3
         END
