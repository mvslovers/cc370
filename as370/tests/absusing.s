* Eine USING auf einem ABSOLUTEN Symbol (#190).
*
* `DUM EQU 0' mit den Feldern als absolute EQU ist die alte Art,
* eine Dummy-Sektion zu schreiben; `USING DUM,2' macht Register 2
* zur Basis fuer diese Abstaende.  as370 trug eine solche USING
* ein und fragte sie nie ab -- es setzte die blanke Distanz mit
* Basis 0 ab.  Ein Halbbyte, keine Meldung, und ein Deck, das
* sauber assembliert und absoluten Speicher adressiert, wo IFOX00
* R2+256 adressiert.
*
* Die dritte Zeile ist die Gegenprobe nach DROP, die vierte die
* wichtigere: die beiden Arten MISCHEN NICHT.  `USING *,15' steht
* ueber dem ganzen CSECT, und IFOX00 nimmt R15 trotzdem nie fuer
* den absoluten Operanden -- weder vor noch nach dem DROP.
*
* Der Fall, an dem die zu weite Fassung scheitert, steht in
* tests/absundef.s -- er braucht ein eigenes Modul, weil IFOX00
* das undefinierte Symbol mit rc 12 meldet und dann kein Deck
* schreibt.
*
*   LA 1,FLD   unter USING DUM,2   4110 2100
*   L  3,FLD   unter USING DUM,2   5830 2100
*   LA 4,FLD   nach DROP 2         4140 0100   nicht 4140 F100
T        CSECT
         USING *,15
DUM      EQU   0
FLD      EQU   DUM+256
         USING DUM,2
         LA    1,FLD
         L     3,FLD
         DROP  2
         LA    4,FLD
         BR    14
         END   T
