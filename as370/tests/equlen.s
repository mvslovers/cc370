* Welches Laengenattribut bekommt ein EQU-Symbol? (#194)
*
* Es ist das L' des LINKESTEN TERMS, und nur dann, wenn dieser
* Term ein Symbol ist -- alles andere ergibt 1.
*
* `1+A' ist der Fall, der die Regel festlegt: es ist der linkeste
* TERM, nicht das erste Symbol irgendwo im Ausdruck.  Ein Ausdruck,
* der mit einer Zahl beginnt, bekommt 1, obwohl ein Symbol folgt.
* Ohne diesen Fall waeren "linkester Term" und "erstes Symbol"
* nicht zu unterscheiden.
*
* as370 gab der ganzen Familie 1.  Das bleibt unsichtbar, bis
* jemand L' liest -- und die SS-Befehle lesen es als IMPLIZITE
* LAENGE.  `MVC @PC00031,0(R1)' wurde D2 00 statt D2 03, ein Byte,
* keine Meldung, waehrend dasselbe Modul vierhundert Karten
* frueher `MVC @PC00031(4),0(R1)' schon richtig hatte: eine
* explizite Laenge fragt dieses Attribut nie.
*
*            A  H  E1 E2 E3 E4 E5 E6 E7 E8
*   main     04 02 01 01 01 01 04 01 01 01   und CLC -> D5 00
*   IFOX00   04 02 04 04 01 01 04 02 02 01   und CLC -> D5 03
T        CSECT
         USING T,12
A        DS    CL4
H        DS    H
E1       EQU   A                 auf ein Label
E2       EQU   A+1               Label plus Zahl
E3       EQU   4                 reine Zahl
E4       EQU   *                 Ortszaehler
E5       EQU   A,4               mit Laengenangabe
E6       EQU   H-A               absoluter Ausdruck
E7       EQU   H                 auf ein Halbwort-Label
E8       EQU   1+A               Zahl plus Label
         DC    AL1(L'A)
         DC    AL1(L'H)
         DC    AL1(L'E1)
         DC    AL1(L'E2)
         DC    AL1(L'E3)
         DC    AL1(L'E4)
         DC    AL1(L'E5)
         DC    AL1(L'E6)
         DC    AL1(L'E7)
         DC    AL1(L'E8)
         CLC   E1,E1             SS: implizite Laenge aus L'E1 -> D5 03
         END   T
