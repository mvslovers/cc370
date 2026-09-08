* Eine AIF-Bedingung wurde bei 126 Zeichen stillschweigend
* abgeschnitten, obwohl beide Aufrufer einen 512-Byte-Puffer
* mitgeben. Der Rest, der ueber sie entscheidet, fiel weg, und das
* AIF verzweigte nach dem, was das Bruchstueck zufaellig bedeutete
* (cc370#236).
*
* AMACLIB(IKJIDENT) hat genau so eine Bedingung: sechs NE-Terme
* ueber drei Karten, 153 Zeichen. Jeder Aufruf fiel deshalb auf den
* Fehlerpfad, meldete MNOTE 8 und verliess das Makro - es erzeugte
* GAR NICHTS, und jedes Symbol aus dem Namensfeld des Aufrufers
* blieb undefiniert. 612 solcher MNOTEs im Korpus, und bis #39 war
* keine davon hoerbar.
*
* G6 ist der Fall: sechs Terme, 137 Zeichen verbunden - ohne Fix
* wird B6 erzeugt. G4 ist die Kontrolle unterhalb der Grenze: vier
* Terme, 91 Zeichen, war immer richtig. Eine Fixture nur aus G4
* haette auf beiden Binaries bestanden.
*
* G2 ist die zweite Kontrolle, in die Gegenrichtung: die Bedingung
* ist WAHR und muss es bleiben. Ein Fix, der einfach mehr Text
* durchreicht, aber die Auswertung verschiebt, faellt dort auf.
*
* Punktzahl:  ohne Fix G4 G2 B6, mit Fix G4 G2 G6
PZ       CSECT
         LCLC  &TYPNAM
&TYPNAM  SETC  'ABC'
         AIF   ('&TYPNAM' NE 'V00' AND '&TYPNAM' NE 'V01'              *
               AND '&TYPNAM' NE 'V02' AND '&TYPNAM' NE 'V03').G4
         DC    C'B4'
         AGO   .E4
.G4      DC    C'G4'
.E4      ANOP
         AIF   ('&TYPNAM' EQ 'ABC').G2
         DC    C'B2'
         AGO   .E2
.G2      DC    C'G2'
.E2      ANOP
         AIF   ('&TYPNAM' NE 'V00' AND '&TYPNAM' NE 'V01'              *
               AND '&TYPNAM' NE 'V02' AND '&TYPNAM' NE 'V03'           *
               AND '&TYPNAM' NE 'V04' AND '&TYPNAM' NE 'V05').G6
         DC    C'B6'
         AGO   .E6
.G6      DC    C'G6'
.E6      ANOP
         END
