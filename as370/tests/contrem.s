* Eine Fortsetzungskarte setzt nur fort, was noch nicht fertig ist.
* Endet der Operand schon auf der ersten Karte, so setzt die naechste
* die BEMERKUNG fort und traegt nichts zur Anweisung bei - IFOX00
* verbraucht sie und verwirft ihren Text.
*
* as370 kuerzte den Puffer am Operandenende und haengte die naechste
* Karte trotzdem an. Harmlos, solange der Operand auf einem Literal
* endet - der Text landete dahinter als Bemerkung. Zerstoerend, wenn
* er auf einer VARIABLEN endet, denn dann verlaengert die Fortsetzung
* deren NAMEN: AMACLIB(IKJIDENT) schreibt `...,C&TYPNAM PARAMETER TYPE
* MESSA' plus `GE SEGMENT', verbunden zu `&TYPNAMGE' - eine
* undefinierte Variable, die zu nichts wird. Das Laengenfeld sagte
* weiter 18 und die Daten waren ein Leerzeichen (cc370#250).
*
* C1 ist der Fall. C2 zeigt, dass es NICHT am Wert liegt: 'SHORT'
* laesst die Karte weit vor Spalte 72 enden und geht genauso verloren.
*
* Die Kontrollen sind der eigentliche Inhalt, denn die erste Fassung
* dieses Fixes liess fuenf davon durchfallen:
*
*   C3  Operand endet auf KOMMA - die Fortsetzung gehoert dazu.
*       Diese Kontrolle steht NICHT hier, sondern ist die ganze
*       uebrige Suite: dcb, contattr, contparen, dc_types und
*       sample8/9 sind genau dieser Fall, und alle fuenf sind an
*       der ersten, zu breiten Fassung dieses Fixes gescheitert.
*   C4  Bedingter Ausdruck ueber zwei Karten - dort bricht der Scan
*       gar nicht ab, also darf auch nichts entschieden werden
*   C6  Bemerkung ohne Variable - war schon immer richtig
*
* Punktzahl:  ohne Fix C1/C2 verlieren die Variable
*             mit Fix  beide ersetzen, C3-C6 unveraendert
         MACRO
         SEG   &T
         DC    AL2(8),AL2(18),C&T PARAMETER TYPE MESSA                 *
               GE SEGMENT
         MEND
         MACRO
         CND   &T
         AIF   ('&T' EQ 'X' AND '&T' NE 'Y'                            *
               AND '&T' NE 'Z').OK
         DC    C'NO'
         MEXIT
.OK      DC    C'OK'
         MEND
CONTREM  CSECT
C1       SEG   'PROBLEM NUMBER'
C2       SEG   'SHORT'
C4       CND   X
C6       DC    C'XY' REMARK TEXT HERE                                  *
               MORE REMARK
         END
