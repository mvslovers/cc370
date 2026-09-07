* Substitution auf einer FORTSETZUNGSKARTE (#141).
*
* mexp_line bekommt zusammengefuegte Karten: eine Anweisung mit
* Fortsetzung ist da laengst eine einzige Zeile von mehreren
* hundert Zeichen.  Der Feldsplitter darf dort nicht bei Spalte 72
* aufhoeren -- sonst wird der Operand still abgeschnitten.
*
*   Grenze bei 72   Konstante endet nach 'XYBBBBBB', Sektion 0x39
*   volle Karte     Konstante vollstaendig, Sektion 0x5B
*
* Gefunden an BLSCAMOD, das acht Bytes einer Konstanten verlor,
* deren Wert auf der zweiten Karte weiterlaeuft.  Die Referenz
* steht hier absichtlich VOR der Fortsetzung und der Rest dahinter,
* damit beide Haelften geprueft werden.
T        CSECT
         LCLC  &V
&V       SETC  'XY'
A        DC    C'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA&V.BBBBB*
               BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBZZZ'
B        DC    C'END'
         END
