* Ein Operand darf eine LISTE von Werten tragen, und jeder davon ist
* eine eigene Konstante: DC H'6,0,17,6,0' sind fuenf Halbworte.
* as370 las den Rumpf mit einem einzigen strtol und erzeugte den
* Wiederholungsfaktor mal den ERSTEN Wert - aus einer fuenfstelligen
* Tabelle wurde ein Halbwort, und jedes Symbol danach lag acht Bytes
* zu frueh, stillschweigend bei rc 0 (cc370#253).
*
* Die Adresstypen ein paar Zeilen darueber haben ihre Liste immer
* geteilt; hier tut es der Festkomma-Zweig auch.
*
* V1 und V5 sind die Faelle. Die Kontrollen sind die drei Formen, die
* schon vorher stimmten, und jede schliesst eine andere falsche
* Verallgemeinerung aus:
*
*   V2  H'7'            ein einzelner Wert - unveraendert
*   V3  3H'7'           Wiederholungsfaktor multipliziert die LISTE,
*                       nicht den ersten Wert; hier ist die Liste
*                       einelementig, also muss dreimal 0007 stehen
*   V4  X'1234',X'5678' zwei getrennte OPERANDEN, nicht eine Liste -
*                       ein Fix, der auf oberster Ebene teilt statt
*                       im Rumpf, faellt hier auf
*   V7  C'AB'           der Zeichenzweig hat seinen eigenen Leser
*
* V5 zeigt ausserdem, dass die Ausrichtung erhalten bleibt: F beginnt
* auf dem Vollwort, also stehen zwei Fuellbytes vor dem ersten Wert.
*
* Punktzahl:  ohne Fix V1 = 0006, V5 = ein Vollwort
*             mit Fix  V1 = fuenf Halbworte, V5 = drei Vollworte
DCVLIST  CSECT
V1       DC    H'6,0,17,6,0'
V2       DC    H'7'
V3       DC    3H'7'
V4       DC    X'1234',X'5678'
V5       DC    F'1,2,3'
V6       DC    F'9'
V7       DC    C'AB'
V8       DC    H'-1,0,-2'
         END
