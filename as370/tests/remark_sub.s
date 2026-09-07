* Bemerkungsfeld und Systemglobal in offenem Code (#141).
*
* Zwei Fragen, beide nur im Listing sichtbar.
*
* 1. Wird das BEMERKUNGSFELD substituiert?
*      IFOX FEVAL60, kein JSUBCMNT   Bemerkung bleibt woertlich,
*                                    auch das nackte &
*      ganze Karte durch msub        Z, und das & faellt weg
*    IBM liefert 2030 nackte & in offenen Bemerkungen aus, in
*    716 MVSBLD-Modulen -- daran haengt, ob feldweise substituiert
*    werden muss.
*
* 2. Erzeugt ein SYSTEMGLOBAL das Modell/Erzeugnis-Paar?
*      paart        zwei Anweisungen, + auf der zweiten
*      paart nicht  eine Anweisung
*    Entscheidet, ob has_varsym() die Karte VOR oder NACH
*    sysvar_sub() prueft.
*
* Kein Deck erfasst: &SYSDATE macht es datumsabhaengig.
T        CSECT
         LCLC  &X
&X       SETC  'Z'
A        DC    C'&X'            BEMERKUNG &X UND & ENDE
B        DC    C'Q'
C        DC    C'&SYSDATE'
         END
