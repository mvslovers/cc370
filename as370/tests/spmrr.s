* split_fields fuellt nur so viele Felder, wie der Operand hergibt.
* Das Ziel ist ein Stapelfeld, das die naechste Anweisung wieder
* benutzt - ein nicht beschriebener Platz haelt also den Text der
* VORIGEN Anweisung an derselben Adresse. Ein Aufrufer, der ein Feld
* liest, ohne die Zahl zu pruefen, bekommt ihn (cc370#252).
*
* SPM hat einen Operanden, der RR-Emitter liest zwei. Also nahm SPM
* sein R2-Feld aus der vorhergehenden RR-Anweisung:
*
*   SR  GR8,GR8   1B88      dann SPM GR8 -> 0488 statt 0480
*   LR  3,7       1837      dann SPM GR8 -> 0487
*   BCR 15,14     07FE      dann SPM GR8 -> 048E
*
* Der Operand ist in allen drei Faellen derselbe. SPM ALLEIN codiert
* richtig - deshalb hat es niemand gefunden: es braucht eine RR-
* Anweisung davor, und `SR GRx,GRx' vor `SPM GRx' ist die uebliche
* Art, die Programmmaske zu loeschen. Real steht die Undichtigkeit
* also immer bereit.
*
* Behoben in split_fields und nicht an der Aufrufstelle: jeder
* Verbraucher einer zu kurzen Operandenliste hat dieselbe Bloesse,
* und aufgefallen waere nur diese eine.
*
* Kontrollen: die zweiwertigen RR-Anweisungen selbst duerfen sich
* nicht bewegen, und BCR/BR lesen nur ein Feld und taten es schon
* immer richtig.
*
* Punktzahl:  ohne Fix 048E 0488 0487 048E, mit Fix viermal 0480
SPMRR    CSECT
GR8      EQU   8
         SPM   GR8
         SR    GR8,GR8
         SPM   GR8
         LR    3,7
         SPM   GR8
         BCR   15,14
         SPM   GR8
         SR    GR8,GR8
         LR    3,7
         BR    14
         BCR   15,14
         END
