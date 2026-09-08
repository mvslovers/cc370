* attr_apos trug ein E, das IFOX00s eigene Menge nicht kennt: dort
* sind es T L I S N K (ifnx1a.asm:4862). E ist in Assembler XF kein
* Attribut - wohl aber ein KONSTANTENTYP (cc370#223).
*
* Also oeffnet DC E'1.0' hier gar keine Zeichenkette. Erst das
* SCHLIESSENDE Anfuehrungszeichen schaltet den Zustand ein, der
* Operand endet nicht mehr am Leerzeichen, und die Bemerkung wandert
* in ihn hinein. Ein Komma darin macht daraus eine zweite Konstante,
* und die Anweisung wird abgelehnt: rc 8, wo IFOX00 rc 0 liefert -
* bei identischen Bytes. Ein Fehlalarm, kein uebersehener Fehler.
*
* Beide Haelften sind noetig, und die Kontrollen zeigen es:
*
*   N1  E + Komma in der Bemerkung   der Fehler
*   N3  E ohne Komma                 wird angenommen
*   N2  F mit demselben Kommatext    wird angenommen
*   N4  C mit demselben Kommatext    wird angenommen
*
* L bleibt draussen: L steht in IFOX00s Menge UND ist der Typ fuer
* erweiterte Gleitkommazahlen, laesst sich also nicht streichen. Es
* hat eine eigene Ursache, reproduziert ganz ohne Bemerkung und ist
* cc370#224. Eine Karte davon hier haette diese Fixture unbrauchbar
* gemacht, weil ihr Deck dann bewusst von IFOX00 abwiche.
*
* Punktzahl: ohne Fix rc 8, mit Fix rc 0; Bytes so wie so gleich.
PB       CSECT
N1       DC    E'1.0'                  SET 1,2 AND 3
N2       DC    F'2'                    SET 1,2 AND 3
N3       DC    E'3.0'                  PLAIN REMARK
N4       DC    C'A'                    SET 1,2 AND 3
         END
