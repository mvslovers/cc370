* Die Bemerkung im offenen Code wird NICHT substituiert (#141), und
* split_card() entscheidet, wo sie anfaengt (#149).
*
* attr_apos() ist rein lexikalisch: es liest das SCHLIESSENDE
* Anfuehrungszeichen einer Zeichenkette, die auf ein Attributzeichen
* endet, als Attribut-Apostroph.  Dann schliesst die Zeichenkette
* nie, das Operandenfeld verschluckt die Bemerkung -- und mit ihr
* wird &X ersetzt, wo IFOX00 es stehen laesst.
*
* Innerhalb einer Zeichenkette kann ein Apostroph sie nur schliessen.
* Das ist das `inq ||', dasselbe Waechterwort, das parse() in #149
* 96 Decks gekostet hat.
*
*   N  ist ein Attributzeichen  -> ohne Waechter wird &X ersetzt
*   M  ist keines               -> Kontrolle, bleibt stehen
*
* IFOX00 laesst beide stehen.
         GBLC  &X
&X       SETC  'WERT'
T        CSECT
         DC    C'ADD 1 TO N'   BEMERKUNG &X ENDE
         DC    C'ADD 1 TO M'   BEMERKUNG &X ENDE
         END   T
