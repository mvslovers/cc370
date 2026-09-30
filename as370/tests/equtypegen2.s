* T' eines Symbols, das ein Makro im RUMPF erzeugt (#525).
*
* equtypegen.s hatte das erzeugte Symbol als Label auf dem
* Makroaufruf stehen, und IFOX00 beantwortet T' dann mit M -- dem
* Typ des Aufrufs, nicht dem des EQU.  Das CVT-Muster ist anders:
* der Name steht nur im Rumpf.  Hier tragen die Aufrufe kein Label.
*
* Drei Regeln stehen zur Wahl, und die Probe trennt sie:
*   (a) erzeugte Symbole sind fuer T' unsichtbar  -> U U U U
*   (b) sichtbar, sobald erzeugt                  -> U X U F
*   (c) sichtbar, auch vorwaerts                  -> X X F F
*
* Reihenfolge der Bytes: H1 vor, H1 nach, H2 vor, H2 nach; zwischen
* H2 vor und H2 nach liegt das F'0' von H2.
         MACRO
         TYP   &S
         LCLC  &T
&T       SETC  T'&S
         DC    C'&T'
         MEND
         MACRO
         GENEQU
H1       EQU   X'40',,C'X'
         MEND
         MACRO
         GENDC
H2       DC    F'0'
         MEND
P3EQUG   CSECT
         TYP   H1
         GENEQU
         TYP   H1
         TYP   H2
         GENDC
         TYP   H2
         END
