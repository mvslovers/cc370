* Laengenattribut L' einer Konstanten ohne explizite Laenge.
*
* Gefunden beim Verdrahten der '&&'-Orakel: amp_fold und
* amp_selfdef sind bis auf genau ein Byte identisch, und das Byte
* ist ein L'.
*
* as370 setzt das Symbol, BEVOR der Rumpf gelesen ist, und nimmt
* dann die explizite Laenge oder 1.  Wo die Laenge aus dem WERT
* kommt, ist das Ergebnis immer 1:
*
*   Typ    Wert        as370   erwartet
*   C      'ABC'         1        3
*   X      'FFFF'        1        2
*   C      3C'AB'        1        2   (eine Konstante, nicht drei)
*
* F, H, A haben eine feste implizite Laenge und stimmen deshalb;
* CL7 hat eine explizite und stimmt auch.  Die Fixture haelt beide
* Gruppen nebeneinander, damit die Grenze im Deck steht.
T        CSECT
CC       DC    C'ABC'
XX       DC    X'FFFF'
BB       DC    B'1010'
FF       DC    F'1'
HH       DC    H'1'
AA       DC    A(T)
DD       DS    CL7
EE       DC    3C'AB'
         DC    AL1(L'CC,L'XX,L'BB,L'FF)
         DC    AL1(L'HH,L'AA,L'DD,L'EE)
         END
