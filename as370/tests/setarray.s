* Ein indiziertes SET-Array kostet EINE Tabellenzeile (#173).
*
* Vorher eine Zeile je zugewiesenem Index: `LCLB &SW(4000)' fuellte
* die 512 Zeilen der lokalen Tabelle beim 513. Index, und global
* waren 6.739 der 6.757 Zeilen von IFCE0155 Array-Elemente, die
* set_find 91.000 mal durchlief -- 98 Millionen Vergleiche.
*
* 20.000 Indizes, weit ueber jeder plausiblen Schranke: der Fall
* unterscheidet damit eine STRUKTURAENDERUNG von einer erhoehten
* Grenze.  Bei 600 wuerde ihn auch ein MAXLSET von 1024 bestehen.
*
* Die ACTR-Karte ist seit #336 noetig: 20.000 Zweige liegen weit ueber
* der Vorgabe 4096, und IFOX00 kennzeichnet eine solche Schleife
* ebenfalls. Sie gehoert zum Fall, nicht zur Umgehung -- ITEMSORT,
* das den Defekt aufdeckte, setzt aus demselben Grund ACTR 200000.
*
*   main e5e4430   local SET-symbol table full (512)
*   mit dieser     rc 0
ASG600    CSECT
         MACRO
         ARR
         LCLB  &SW(40000)
         ACTR  100000                                                 
         LCLA  &I
&I       SETA  0
.L       ANOP
&I       SETA  &I+1
&SW(&I)  SETB  1
         AIF   (&I LT 20000).L
         DC    AL2(&I)
         MEND
         ARR
         END
