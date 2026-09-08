* Der C'..'-Selbstdefinitionsterm hatte DREI Leser - den Operanden-
* Auswerter, den SETA-Leser und den Auswerter der bedingten
* Assemblierung - und alle drei fassten `&&' zu einem `&' zusammen,
* keiner den doppelten Apostroph. `QUOTE EQU C''''' brach also am
* ersten Apostroph des Paares ab und ergab NULL (cc370#238).
*
* `DC C'''' war die ganze Zeit richtig: der DC-Zweig hat seinen
* eigenen Scanner, und der kannte die Regel. Genau das ist der Punkt -
* der Fehler war nicht der fehlende Zweig, sondern drei Leser
* derselben Syntax, die man im Gleichschritt halten muss. Jetzt ist es
* eine Funktion.
*
* Q1 ist der Fall. Die Kontrollen:
*
*   Q2  EQU C'A'      gewoehnliches Zeichen - war immer richtig
*   Q3  DC  C''''     der Pfad, der es schon konnte
*   Q4  EQU C'&&'     die &&-Regel muss ueberleben
*   Q5  EQU X'7D'     der X-Zweig bleibt unberuehrt
*   Q6  EQU C''''''   zwei Paare ergeben zwei Bytes, nicht eines
*
* Punktzahl:  ohne Fix 00 C1 7D 50 7D 0000
*             mit Fix  7D C1 7D 50 7D 7D7D
EQUQ     CSECT
Q1       EQU   C''''
Q2       EQU   C'A'
Q4       EQU   C'&&'
Q5       EQU   X'7D'
Q6       EQU   C''''''
         DC    AL1(Q1)
         DC    AL1(Q2)
Q3       DC    C''''
         DC    AL1(Q4)
         DC    AL1(Q5)
         DC    AL2(Q6)
         END
