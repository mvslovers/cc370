* Die IMPLIZITE Laenge eines SS-Operanden, zwei Wege (#201).
*
* Eine WEGGELASSENE Laenge ist keine Laenge null.  `CLC DA-D(,5)'
* schreibt die Klammerliste fuer die Basis und laesst das
* Laengenfeld leer; IFOX00 nimmt dann die implizite Laenge, als
* stuende gar keine Liste da.  as370 las das leere Feld als 0.
*
* Und ein ABSOLUTER Praefix hat trotzdem ein Laengenattribut.
* `PSAAOLD-PSA' ist eine Differenz in EINER Dummy-Sektion, also
* absolut -- as370 setzte r_len dort nie, und der Operand ging mit
* Laengenbyte 0 hinaus.  Das ist die Form aus IGC121; die mit
* Klammer die aus IEDAYO.
*
* Die letzte Zeile ist die Gegenprobe: ein rein numerischer
* Praefix hat kein Laengenattribut und muss 1 bleiben.
*
*   main 021db88   D503 D500 D500 D503 D500
*   IFOX00, dies   D503 D503 D503 D503 D500
D        DSECT
DA       DS    CL4
DB       DS    CL4
T        CSECT
         USING T,12
         LR    5,1
B        DS    CL4
         CLC   DA-D(4,5),B       Laenge und Basis explizit
         CLC   DA-D(,5),B        Laenge weggelassen, Basis explizit
         CLC   DA-D,B            gar keine Klammer, absolut
         CLC   B,B               beides impliziert, relokierbar
         CLC   8(,5),B           numerischer Praefix, bleibt 1
         BR    14
         END   T
