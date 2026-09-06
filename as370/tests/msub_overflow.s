* Ueberlauf des Substituierers msub -- ohne #141 zu brauchen.
*
* Substitution DEHNT, und um einen Faktor, den keine Aufrufstelle
* aus ihrer eigenen Eingabe abschaetzen kann: eine Referenz kostet
* zwei Zeichen zu schreiben, vref liefert bis zu 95 zurueck.  Das
* sind 47,5fach, und alle vier Aufrufstellen reichen msub einen
* automatischen Puffer von 256 oder 1024 Byte herein.
*
* &X wird viermal verdoppelt (10 -> 95, dort geklemmt) und dann
* viermal verkettet: 380 Byte in eval_setc's sub[256].
* MBIG deckt dieselbe Dehnung fuer mexp_macro's ex[1024] und
* render_model's sub[256] ab -- zwoelf Referenzen zu je 95 Byte.
*
* Vor der Begrenzung meldete ASAN hier stack-buffer-overflow in
* msub, und as370 endete trotzdem mit RC 0.  Ohne Sanitizer sieht
* diese Fixture nichts -- der Test baut sich deshalb einen.
         MACRO
         MBIG  &V
BIG      DC    C'&V&V&V&V&V&V&V&V&V&V&V&V'
         MEND
T        CSECT
         LCLC  &X,&L
&X       SETC  'AAAAAAAAAA'
&X       SETC  '&X.&X'
&X       SETC  '&X.&X'
&X       SETC  '&X.&X'
&X       SETC  '&X.&X'
&L       SETC  '&X&X&X&X'
         MBIG  &X
         END
