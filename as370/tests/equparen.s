* L' eines EQU ist die Laengenangabe des LINKESTEN TERMS (cc370#194).
* Eine Gruppierungsklammer verbirgt diesen Term aber nicht: IFOX00 gibt
* (A+4) die Laenge von A. as370 pruefte direkt auf einen Buchstaben,
* fand die Klammer und lieferte 1 (cc370#221).
*
* Die Regel ist mit dem Orakel festgenagelt, nicht geraten:
*
*   F1 (S1+4)      7   Klammer wird uebersprungen
*   F3 ((S1))      7   auch mehrere
*   F4 (S1)+4      7   die Klammer schliesst vor dem Rest
*   F5 (S2+1)      3   anderes Symbol, andere Laenge
*
* Drei Kontrollen, die 1 bleiben MUESSEN, und jede schliesst eine
* andere falsche Regel aus:
*
*   F2 (4+S1)      1   linkester Term ist die Zahl - wer nur "erstes
*                      Symbol im Ausdruck" sucht, faellt hier auf
*   F6 (X'04'+S1)  1   selbstdefinierender Term, kein Symbol
*   F7 ( S1+4)     1   NUR die Klammer wird uebersprungen, nicht das
*                      Leerzeichen dahinter. IFOX00 meldet dafuer
*                      IFO234 (rc 8), as370 schweigt - eine
*                      Meldungsluecke, die hier bewusst nicht
*                      mitbehoben wird. Die Bytes sind gleich.
*
* Punktzahl:  ohne Fix 7x 01
*             mit Fix  07 01 07 07 03 01 01.
P8       CSECT
S1       DS    CL7
S2       DS    CL3
F1       EQU   (S1+4)
F2       EQU   (4+S1)
F3       EQU   ((S1))
F4       EQU   (S1)+4
F5       EQU   (S2+1)
F6       EQU   (X'04'+S1)
F7       EQU   ( S1+4)
M1       DC    AL1(L'F1)
M2       DC    AL1(L'F2)
M3       DC    AL1(L'F3)
M4       DC    AL1(L'F4)
M5       DC    AL1(L'F5)
M6       DC    AL1(L'F6)
M7       DC    AL1(L'F7)
         END
