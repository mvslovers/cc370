* Eine fuehrende Klammer in einem Maschinenoperanden ist eine
* GRUPPE, kein Indexpaar. as370 las sie als Indexliste und verlor die
* Distanz mit ihr: `L 15,(FIELD-BASE)(9)' kam als 58F0 0000 heraus -
* Basis 0, Distanz 0, bei rc 0 und auf beiden Seiten stumm. Bei
* `LA 1,(4-1)' war es schlimmer: die 3 wurde als BASISREGISTER
* genommen (cc370#247).
*
* Zwei Stellen mussten sich aendern, und das ist der Punkt: erst die
* POSITIONSREGEL (eine Klammer am Anfang steht dort, wo ein Operator
* stuende, ist also eine Gruppe), dann die AUSWERTUNG der Distanz -
* expr_val liest eine fuehrende Klammer selbst wieder als Index und
* liefert 0. Nach der ersten Aenderung allein stimmten die Register
* und alle Distanzen waren null.
*
* Gemessen an IFOX00:
*
*   R1  L  15,(FIELD-BASE)(9)    58F9 0010  zweite Gruppe indiziert
*   R2  L  15,(FIELD-BASE)(,9)   58F0 9010   Komma macht 9 zur Basis
*   R4  LA 1,(2)                 4110 0002   Distanz 2, NICHT Basis 2
*   R5  LA 1,(4-1)               4110 0003
*   R7  LA 1,(FIELD-BASE)        4110 0010
*   R8  L  15,(FIELD-BASE)(2,9)  58F2 9010   beide Gruppen
*
* Kontrollen, die sich NICHT bewegen duerfen:
*
*   R3  L  15,FIELD-BASE(9)      ohne Klammer, war immer richtig
*   R6  LA 1,4-1                 dasselbe ohne Klammer
*   R9  LA 1,2(3)                gewoehnlicher Index
*   RA  BC 15,*(9)               nach dem Ortszaehler IST (9) der
*                                Index - die Positionsregel muss das
*                                weiterhin unterscheiden, sonst faellt
*                                sie hier auf. Die zweite USING ist
*                                nur dafuer da, damit dieser Fall
*                                adressierbar ist und die Fixture
*                                ohne Diagnose durchlaeuft.
BASE     DSECT
         DS    CL16
FIELD    DS    F
RXPAREN  CSECT
         USING BASE,9
         USING RXPAREN,10
R1       L     15,(FIELD-BASE)(9)
R2       L     15,(FIELD-BASE)(,9)
R3       L     15,FIELD-BASE(9)
R4       LA    1,(2)
R5       LA    1,(4-1)
R6       LA    1,4-1
R7       LA    1,(FIELD-BASE)
R8       L     15,(FIELD-BASE)(2,9)
R9       LA    1,2(3)
RA       BC    15,*(9)
         END
