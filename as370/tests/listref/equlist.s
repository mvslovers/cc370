* Ein EQU steht nicht am Ortszaehler - es benennt einen WERT. IFOX00
* listet es so: LOC bleibt leer, der Wert des Symbols steht in ADDR2
* (Spalten 29-33). as370 druckte stattdessen den Ortszaehler in LOC,
* eine Zahl, die mit der Anweisung nichts zu tun hat (cc370#226).
*
* Das hat an einem Tag zwei Befunde gekostet, in zwei Sitzungen, beide
* aus dem Lesen dieser Spalte als Wert: cc370#224 und die PREFL-Spur
* an #201. DL unten ist genau die PREFL-Form - eine Differenz in einer
* DSECT, deren Ortszaehler an dieser Karte zufaellig anders steht als
* der Wert.
*
* E3 ist absolut, E1/E2 relocierbar, E4 eine Differenz im selben
* Abschnitt. ORG und LTORG behalten LOC, denn sie bewegen den Zaehler
* wirklich - hier steht ein ORG als Gegenprobe.
EQULIST  CSECT
A1       DS    CL7
A2       DS    CL3
E1       EQU   A1
E2       EQU   A1+4
E3       EQU   8
E4       EQU   A2-A1
         DC    AL1(E4)
         DS    CL4
         ORG   *-2
         DS    CL2
DMAP     DSECT
D1       DS    CL4
D2       DS    CL2
DL       EQU   D2-DMAP
         END
