* Die Datenadresse eines CCW ist relocierbar - auch dann, wenn
* sie als Ortszaehler `*' geschrieben ist. as370 verlangte hier
* ein SYMBOL, und sym_find("*") findet nichts: der RLD-Eintrag
* fiel weg (cc370#210).
*
* K1 und K2 sind DASSELBE Konstrukt, zweimal geschrieben - K1
* nennt seine eigene Marke, K2 den Ortszaehler. Beide muessen
* genau einen 3-Byte-Eintrag erzeugen; die Fixture beweist sich
* also selbst, bevor IFOX00 ueberhaupt gefragt wird.
*
* K4 ist die Kontrolle in die Gegenrichtung: ein CCW im CSECT,
* dessen Ziel in einer DSECT liegt, erzeugt KEINEN Eintrag. Ein
* Fix, der nur `if (rc)' prueft, relociert K4 mit - und faellt
* hier auf.
*
* Punktzahl:  ohne Fix 2 RLD-Eintraege, mit Fix 3.
CCWSTAR  CSECT
BUF      DS    CL8
K1       CCW   X'02',K1,X'70',1
K2       CCW   X'02',*,X'70',1
K3       CCW   X'02',BUF,X'70',1
K4       CCW   X'02',DFLD,X'70',1
DMAP     DSECT
DFLD     DS    CL8
         END
