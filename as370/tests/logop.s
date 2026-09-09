* Eine schliessende Klammer beendet einen Term genauso wie ein
* schliessendes Anfuehrungszeichen - ein Operator, der daran stoesst,
* ist ein eigenes Token. Leerzeichen um einen logischen Operator sind
* optional, und IBMs Makros lassen sie weg (cc370#262):
*
*     AIF   (NOT(&B(1) AND &B(2) AND &B(3))OR '&ELSE' EQ '').C5
*
* steht so in PVTMAC(GOIF1). Ohne die Regel klebte das OR mitsamt
* allem dahinter an der Gruppe, die Bedingung las sich als ein
* einziger Faktor und kam falsch heraus. Acht IFNX*-Module fallen
* deshalb auf .ERR3 und melden REDUNDANT LOGIC.
*
* Das ist das Spiegelbild der Regel, die #243 auf der anderen Seite
* des Operators brauchte: drei Trennzeichen, eine Regel.
*
* L1 ist der Fall, L2 dieselbe Bedingung MIT Leerzeichen - sie war
* immer richtig, und eine Fixture nur daraus besteht auf beiden
* Binaries.
*
* Die Wahrheitswerte sind der eigentliche Trick: alle drei &B sind 1,
* also ist NOT(...) FALSCH, und &ELSE ist leer, also ist der zweite
* Operand WAHR. Nur so entscheidet das ODER etwas. Mit &B = 0 waeren
* beide Operanden wahr und jede Zerlegung kaeme auf wahr heraus -
* meine erste Fassung dieser Fixture tat genau das und bestand
* fehlerhaft.
*
* L3 ist die Kontrolle in die Gegenrichtung: NOT( ohne Leerzeichen auf
* der OEFFNENDEN Seite war schon immer richtig und darf sich nicht
* bewegen.
*
* Punktzahl:  ohne Fix NO1 OK2 OK3, mit Fix OK1 OK2 OK3
         MACRO
         QP    &ELSE
         LCLB  &B(3)
&B(1)    SETB  1
&B(2)    SETB  1
&B(3)    SETB  1
         AIF   (NOT(&B(1) AND &B(2) AND &B(3))OR '&ELSE' EQ '').A
         DC    C'NO1'
         AGO   .B
.A       DC    C'OK1'
.B       AIF   (NOT(&B(1) AND &B(2) AND &B(3)) OR '&ELSE' EQ '').C
         DC    C'NO2'
         AGO   .D
.C       DC    C'OK2'
.D       AIF   (NOT(&B(1) AND &B(2))).E
         DC    C'OK3'
         MEXIT
.E       DC    C'NO3'
         MEND
LOGOP    CSECT
         QP
         END
