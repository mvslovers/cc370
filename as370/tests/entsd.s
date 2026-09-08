* ENTRY auf den Namen des Kontrollabschnitts selbst (#199).
*
* Der SD IST dieser Einsprungpunkt, IFOX00 gibt ihn allein aus.
* as370 setzte zusaetzlich eine LD-Eintragung ab -- und zwar als
* ERSTE, weil das ENTRY der CSECT-Karte vorausgeht: in IERABW
* stehen 104 Karten dazwischen.  Weil das ENTRY verarbeitet wird,
* solange der Name noch unbekannt ist, laesst sich die LD dort
* nicht unterdruecken; sie faellt erst bei der Ausgabe weg.
*
* LAB ist die Gegenprobe: ein ENTRY auf eine gewoehnliche Marke
* bekommt seine LD weiterhin.
*
*   main d398f1e   T LD, LAB LD, T SD
*   IFOX00, dies   LAB LD, T SD
         ENTRY T
         ENTRY LAB
T        CSECT
LAB      DS    0H
         BR    14
         END   T
