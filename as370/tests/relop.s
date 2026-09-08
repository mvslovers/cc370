* Leerzeichen um einen Vergleichsoperator sind OPTIONAL, und IBMs
* Makros lassen sie routinemaessig weg. AMODGEN(SYSEVENT) bildet seine
* ganze Mnemonik-Tabelle so ab:
*
*     AIF   ('&EVENT'EQ'USERRDY').EOK
*
* as370s Tokenizer beendete das Operator-Token nicht am OEFFNENDEN
* Anfuehrungszeichen des rechten Operanden - es klebte zu einem Token
* EQ'USERRDY' zusammen, das kein Vergleichsoperator ist. Also wurde der
* Vergleich nie durchgefuehrt und das AIF fiel durch (cc370#243).
*
* Fuer SYSEVENT hiess das: die Kette lief an ihrem Treffer vorbei bis
* zu einer spaeteren Mnemonik UND ueberging ENTRY=BRANCH. Code 53 und
* ein SVC, wo IFOX00 Code 4 und ein BALR hat.
*
* Q2 ist die Kontrolle, die immer richtig war: dieselbe Bedingung MIT
* Leerzeichen. Eine Fixture nur daraus besteht auf beiden Binaries.
* Q3 prueft NE, Q4 einen Operator vor einer Klammer-Gruppe, und Q5 ist
* die Kontrolle in die Gegenrichtung: K'&E darf nicht zerlegt werden,
* das Apostroph gehoert dort zum Attribut, nicht zu einem Operator.
* (L'SYM in derselben Stellung ist auf BEIDEN Binaries falsch und hat
* mit dieser Aenderung nichts zu tun - cc370#244.)
*
* Punktzahl:  ohne Fix NOEQ OKSP NONE NOOR OKAT
*             mit Fix  OKEQ OKSP OKNE OKOR OKAT
         MACRO
         QAA   &E
         AIF   ('&E'EQ'USERRDY').A
         DC    C'NOEQ'
         MEXIT
.A       DC    C'OKEQ'
         MEND
         MACRO
         QBB   &E
         AIF   ('&E' EQ 'USERRDY').B
         DC    C'NOSP'
         MEXIT
.B       DC    C'OKSP'
         MEND
         MACRO
         QCC   &E
         AIF   ('&E'NE'ZZZ').C
         DC    C'NONE'
         MEXIT
.C       DC    C'OKNE'
         MEND
         MACRO
         QDD   &E
         AIF   ('&E'EQ'USERRDY' OR '&E'EQ'X').D
         DC    C'NOOR'
         MEXIT
.D       DC    C'OKOR'
         MEND
         MACRO
         QEE   &E
         AIF   (K'&E EQ 3).E
         DC    C'NOAT'
         MEXIT
.E       DC    C'OKAT'
         MEND
RELOP    CSECT
FLD      DS    F
         QAA   USERRDY
         QBB   USERRDY
         QCC   USERRDY
         QDD   USERRDY
         QEE   ABC
         END
