* Eine Differenz von Symbolen aus VERSCHIEDENEN Kontrollabschnitten
* ist nicht absolut: ihr Wert haengt davon ab, wohin der Binder die
* beiden Abschnitte legt. IFOX00 schreibt dafuer ein VORZEICHEN-
* BEHAFTETES PAAR - negativ fuer den subtrahierten Abschnitt, positiv
* fuer den addierten. as370 hielt den Ausdruck fuer absolut, weil
* expr_val_full die NETTO-Relocierbarkeit meldet und sich die beiden
* Abschnitte gerade aufheben (cc370#209).
*
* C4 legt die Regel fest: zwei Terme desselben Abschnitts ergeben
* ZWEI Eintraege, also einer je EINHEIT der Summe, nicht einer je
* Abschnitt. Ohne diesen Fall waeren "je Abschnitt" und "je Term"
* nicht zu unterscheiden.
*
* Drei Kontrollen in die Gegenrichtung: C2 und C6 sind Differenzen
* INNERHALB eines Abschnitts und erzeugen gar nichts - genau der
* Fall, der den Ausdruck wirklich absolut macht -, und bei C5 hebt
* sich XSECTB auf, so dass nur ein Eintrag bleibt. Ein Fix, der
* jeden genannten Abschnitt relociert, faellt an allen dreien auf.
*
* Punktzahl:  ohne Fix 3 RLD-Eintraege, mit Fix 6.
XSECTA   CSECT
A1       DS    F
A2       DS    F
XSECTB   CSECT
B1       DS    F
B2       DS    F
XSECTA   CSECT
C1       DC    A(B1-A1)
C2       DC    A(A2-A1)
C3       DC    A(B1)
C4       DC    A(B1+B2)
C5       DC    A(A1-B1+B1)
C6       DC    A(B2-B1)
         END
