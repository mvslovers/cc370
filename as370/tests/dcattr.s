* dc_split zerlegt den DC-Operanden an Kommas der obersten Ebene und
* hielt JEDEN Apostroph fuer einen Zeichenkettenbeginn. Der Apostroph
* von L'/K'/N'/T' ist aber ein Attribut, kein Anfuehrungszeichen: nach
* einer ungeraden Zahl davon steht der Splitter "in einer Zeichen-
* kette", und das naechste Komma trennt nicht mehr (cc370#218).
*
* G1 verliert dadurch X'FF' vollstaendig - stillschweigend, rc 0, ohne
* eine einzige Meldung. G2 verschmilzt beide Konstanten und meldet ein
* undefiniertes Symbol namens AL1.
*
* G3 ist die Kontrolle, die auch OHNE Fix stimmt: das fuehrende X'FF'
* stellt die Paritaet wieder her, also faellt der Fehler dort nicht
* auf. Eine Fixture nur aus G3 waere ein Nicht-Test.
*
* G5 und G6 sind die Kontrollen in die Gegenrichtung. G6 ist die
* scharfe: eine echte Zeichenkette, die auf L endet. Wer den
* Attributtest auf das SCHLIESSENDE Anfuehrungszeichen anwendet,
* macht daraus ein Attribut und verliert wieder alles danach - die
* Regel gilt nur beim OEFFNENDEN, also nur ausserhalb einer
* Zeichenkette.
*
* split_fields und der Wertesplitter im DC-Zweig tragen genau diesen
* Test seit jeher; dc_split, der dritte Leser derselben Syntax, nie.
*
* Punktzahl:  ohne Fix 8 Bytes ab FLD+0, mit Fix 11.
P6       CSECT
FLD      DS    CL7
G1       DC    AL1(L'FLD),X'FF'
G2       DC    AL1(L'FLD),AL1(L'FLD)
G3       DC    X'FF',AL1(L'FLD)
G4       DC    AL1(L'FLD)
G5       DC    C'A',X'FF'
G6       DC    C'L',X'FF'
         END
