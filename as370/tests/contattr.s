* Fortgesetzte Anweisung: das Attribut-Apostroph (#184).
*
* join_cont() entscheidet, wo der Operand der ERSTEN Karte endet.
* Kippt der Quote-Zustand am L', gilt das Blank davor als in
* Anfuehrungszeichen, der Operand endet nicht, und die Bemerkung
* wird in die zusammengefaltete Anweisung uebernommen.
*
* Drei Faelle, und der dritte ist der wichtige:
*
*   1  L'A  -> ohne Fix wird &C leer:      DC C''  statt DC C'CC'
*   2  4    -> Kontrolle ohne Attribut:    DC C'DD'
*   3  'S'  -> die Zeichenkette endet auf ein Attributzeichen.
*      attr_apos() ist rein lexikalisch und liest das
*      SCHLIESSENDE Anfuehrungszeichen als Attribut; ohne das
*      `q ||' schliesst die Kette nie.  Genau diese Auslassung
*      kostete in #182 sechsundneunzig Decks.
*      IFOX00: DC C'EE'
         MACRO
&L       MYM   &A,&B,&C
&L       DC    C'&C'
         MEND
T        CSECT
A        DC    CL4'ABCD'
         MYM   L'A,BB,                    BEMERKUNG                    X00010000
               CC                                                       00020000
         MYM   4,BB,                      BEMERKUNG                    X00030000
               DD                                                       00040000
         MYM   'S',BB,                    BEMERKUNG                    X00050000
               EE                                                       00060000
         END   T
