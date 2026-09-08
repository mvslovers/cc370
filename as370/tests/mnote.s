* MNOTE ist die einzige Diagnose, die ein Makro ueber seinen AUFRUFER
* stellen kann. as370 uebersprang die Anweisung ganz: keine Listing-
* zeile, keine Meldung, keine Schwere. Die IBM-Konvention lautet
* IHBERMAC -> MNOTE 8/12 -> MEXIT, das Makro LOESCHT also die
* Anweisung und meldet den Fehler nur ueber die MNOTE - unter as370
* wurde ein Makro-Argumentfehler damit zu Schweigen bei rc 0
* (cc370#39). Ein solcher Fall ist bereits ausgeliefert worden:
* libc370 @@aopen.asm rief FREEMAIN mit LV=(0) und SP= zugleich,
* freemain.macro lehnt das mit MNOTE 12 ab und verliess sich, und die
* Aufraeumung fehlte im Objekt.
*
* Drei Formen, und IFOX00 behandelt sie verschieden - gemessen, nicht
* angenommen:
*
*   MNOTE 8,'text'   Schwere 8, GEZAEHLT, Listing "    8,text"
*   MNOTE *,'text'   Kommentar: Schwere 0, NICHT gezaehlt, "*,text"
*   MNOTE 'text'     ohne Schwere: 0, NICHT gezaehlt, "text"
*
* Genau das sind die Kontrollen: die beiden unteren Formen duerfen
* weder die Zahl der gekennzeichneten Anweisungen noch den Returncode
* beruehren. Ein Fix, der jede MNOTE zaehlt, faellt daran auf.
*
* Der doppelte Apostroph in der letzten wird zu einem einzigen - im
* Listing wie in der Meldung.
*
* Punktzahl:  ohne Fix rc 0, nichts gemeldet
*             mit Fix  rc 12, 4 Anweisungen gekennzeichnet
         MACRO
         TM1
         MNOTE 8,'EIGHT FROM A MACRO'
         MNOTE 4,'FOUR FROM A MACRO'
         MNOTE *,'COMMENT FORM'
         MNOTE 'NO SEVERITY GIVEN'
         MNOTE 12,'TWELVE WITH A ''QUOTE'' INSIDE'
         MEND
PM       CSECT
         TM1
         MNOTE 4,'FOUR IN OPEN CODE'
         DC    C'X'
         END
