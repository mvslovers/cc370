* Eine ESDID gehoert zum ESD-EINTRAG, nicht zum Symbol (#199).
*
* Ein Name kann zwei Eintraege haben: ein Kontrollabschnitt, der
* seinen eigenen Namen als V-Kon fuehrt, hat ein SD UND ein ER.
* IFOX00 numeriert beide getrennt.
*
* as370 hielt die Nummer am Symbol, also ueberschrieb die ER-
* Vergabe die des SD.  Im RLD-Feld R faellt das nicht auf -- dort
* ist die ER-Nummer ohnehin richtig, sie stimmte also zufaellig --
* wohl aber in P, das den Abschnitt nennt, in dem die Adress-
* konstante STEHT: jeder RLD-Eintrag des Moduls sagte P=0x0074,
* wo IFOX00 P=0x0001 sagt.  Und weil eine ESD-Karte EINE Anfangs-
* nummer traegt und die Eintraege ihr der Reihe nach folgen,
* verschob der ueberschriebene Wert die ganze erste Karte.
*
*   main     SD=2 ER=3 EXTA=4   und P=0002
*   IFOX00   SD=1 ER=2 EXTA=3   und P=0001
*
* Die zweite Zeile ist die Gegenprobe: R nimmt weiterhin das ER
* (2), nicht das SD (1), denn eine V-Kon nennt ein EXTERNES
* Symbol -- auch wenn es hier zugleich definiert ist.
T        CSECT
         USING T,12
         L     1,=V(T)
         L     2,=V(EXTA)
         BR    14
         LTORG
         END   T
