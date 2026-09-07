* Wo endet das Operandenfeld einer FORTGESETZTEN Karte (#154)?
*
* Makroaufruf: am ersten Blank AUSSERHALB von Anfuehrungszeichen,
* auch mitten in einer offenen Klammer.  Der Rest bis Spalte 71 ist
* Remark und darf nicht in die Fortsetzung gefaltet werden.
*
* AIF/SETB: der Operand IST ein Ausdruck, seine Operatoren sind
* durch Blanks getrennt.  Dort zaehlt die Klammertiefe -- sonst
* zerreisst jede fortgesetzte Bedingung.
*
* Beide Haelften stehen hier, weil jede Regel allein die andere
* bricht: mit Klammertiefe verschluckt MYM den Remark, ohne sie
* zerfaellt das AIF.
*
*   MYM  -> CL8'CC'   Remark verworfen
*   MYC  -> C'JA  '   Ausdruck ueber die Fortsetzung hinweg
         MACRO
&L       MYM   &A
&L       DC    CL8'&A(3)'
         MEND
         MACRO
         MYC   &X
         AIF   ('&X' EQ 'ROT' OR                                       X        
               '&X' EQ 'BLAU').JA                                               
         DC    C'NEIN'
         MEXIT
.JA      ANOP
         DC    C'JA  '
         MEND
T        CSECT
         MYM   (AA,BB,                          REMARK                 X00010000
               CC)                                                      00020000
         MYC   BLAU
         END   T
