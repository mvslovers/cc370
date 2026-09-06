* Ist C'&&' als SELBSTDEFINIERTER Term ein Byte oder zwei?
*
* amp_fold.s hat die DC-Konstante geklaert: die DC-Verarbeitung
* faltet.  Offen bleibt der AUSDRUCKS-Kontext -- C'&&' in einer
* Arithmetik -- und die Laenge eines Literals.
*
*   Regel A  auch dort gefaltet
*              A = 0050   ein Byte, Wert X'50'
*              B = 02     L'CC ist 2
*   Regel B  nur die DC-Verarbeitung faltet
*              A = 5050   zwei Byte
*              B = 04     L'CC ist 4
*
* as370 faltet heute an KEINER der beiden Stellen.  Wird nur die
* DC-Seite repariert, muss diese Fixture sagen, ob die
* Ausdrucksseite mitgeht.
T        CSECT
         USING T,15
A        DC    AL2(C'&&')
B        DC    AL1(L'CC)
CC       DC    C'&&&&'
         MVC   0(1,1),=C'&&&&'
         DC    C'END'
         LTORG
         END
