* T' eines Symbols, das ein MAKRO erzeugt (#525).
*
* equtype.s misst das Typ-Operand-EQU im offenen Code.  Hier steht
* dasselbe EQU in einem Makrorumpf -- so wie in CVT, IHAPSA und
* 1 108 weiteren Stellen der MVS-3.8-maclib.
*
* Drei Regeln stehen zur Wahl, und die Probe trennt sie:
*   (a) erzeugte Symbole sind fuer T' unsichtbar  -> U U U U
*   (b) sichtbar, sobald erzeugt                  -> U X U F
*   (c) sichtbar, auch vorwaerts                  -> X X F F
* Die Kontrolle O1 steht im offenen Code und muss in allen drei
* Faellen vorwaerts wie rueckwaerts Y sein.
*
* Reihenfolge der Bytes: G1 vor, G1 nach, G2 vor, G2 nach, O1 vor,
* O1 nach; zwischen G2 vor und G2 nach liegt das F'0' von G2.
*
* Gemessen (IFOX00, MVSTK5-REF, JOB00290): M M M M Y Y -- keine der
* drei Regeln.  G1 und G2 sind Label auf dem MAKROAUFRUF, und T'
* eines solchen Labels ist M.  Die Probe verwechselt also das
* erzeugte Symbol mit dem Aufruf; equtypegen2.s trennt die beiden
* und misst U U U U, Regel (a).  as370 gibt hier U statt M.
         MACRO
         TYP   &S
         LCLC  &T
&T       SETC  T'&S
         DC    C'&T'
         MEND
         MACRO
&S       GENEQU
&S       EQU   X'40',,C'X'
         MEND
         MACRO
&S       GENDC
&S       DC    F'0'
         MEND
P2EQUG   CSECT
         TYP   G1
G1       GENEQU
         TYP   G1
         TYP   G2
G2       GENDC
         TYP   G2
         TYP   O1
O1       EQU   X'40',,C'Y'
         TYP   O1
         END
