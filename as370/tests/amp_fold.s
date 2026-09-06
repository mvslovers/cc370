* Faltung von '&&' in einer C-Konstanten OHNE jede Substitution.
*
* as370 widerspricht sich heute selbst, bei identischem Quelltext:
*
*   offener Code    DC C'&&'   ->  5050   zwei Bytes
*   im Makrorumpf   DC C'&&'   ->  50     ein Byte
*
* Einer der beiden Pfade ist falsch.  Die Fixture trennt sie:
*
*   Regel A  immer falten
*            A = 1 Byte, B = 3 Bytes, C = 2 Bytes, L'A=1, L'B=3
*   Regel B  nur bei Substitution falten
*            A = 2 Bytes, B = 4 Bytes, C = 4 Bytes, L'A=2, L'B=4
*
* Kein Variablensymbol im Modul, damit die Frage allein an der
* DC-Verarbeitung haengt und nicht am Substituierer.
*
* 422 DC-Operanden in 139 MVSBLD-Modulen haengen an der Antwort.
T        CSECT
A        DC    C'&&'
B        DC    C'A&&B'
C        DC    C'&&&&'
LA       DC    AL1(L'A)
LB       DC    AL1(L'B)
         END
