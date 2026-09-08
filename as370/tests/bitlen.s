* Ein Laengenmodifikator darf in BITS angegeben werden: DC AL.12(1)
* ist ein Zwoelf-Bit-Feld. as370s Laengenauswertung las L und erwartete
* Ziffern, also beendete der Punkt sie mit der Laenge NULL - die
* Konstante erzeugte nichts und bewegte den Ortszaehler nicht,
* stillschweigend bei rc 0. Jedes Symbol dahinter lag um genau das zu
* frueh, was nie reserviert wurde: ein Kontrollabschnitt je Modul zu
* kurz, beide Assembler stumm (cc370#240, die Ursache hinter #205).
*
* Die Regeln sind am Orakel festgenagelt, nicht angenommen:
*
*   B1  AL.12(1),AL.4(2)   0012    12+4 fuellen zwei Bytes genau
*   B2  BL.1'1',FL.7'7',   8743    zusammenhaengend gepackt
*   B3  AL.12(1)           0010    rechts auf zwei Bytes aufgefuellt
*   B4  XL.4'F'            F0      rechts auf ein Byte
*   B6  AL.3(5)            A0      der Wert steht links im Feld
*   B7  3AL.4(1)           1110    der Wiederholungsfaktor packt mit
*   B8  AL.12(1),AL2(3)    00100003  ein Nicht-Bit-Operand spuelt
*   B9  AL.4(1),C'A',      10C120  und zwar mitten im Satz
*   BA  DS AL.12,AL.4      2 Bytes reserviert, nichts erzeugt
*
* KONTROLLEN OHNE BITMODIFIKATOR - sie muessen Byte fuer Byte gleich
* bleiben, denn an ihnen haengen die 4831 identischen Module:
*
*   C1  AL1(1)   C2  XL1'F'   C3  AL2(1)   C4  CL3'AB'   C5  F'7'
*
* Punktzahl:  ohne Fix erzeugen B1-BA nichts, C1-C5 unveraendert
BITLEN   CSECT
B1       DC    AL.12(1),AL.4(2)
B2       DC    BL.1'1',FL.7'7',AL.4(4),FL.4'3'
B3       DC    AL.12(1)
B4       DC    XL.4'F'
B5       DC    C'Z'
B6       DC    AL.3(5)
B7       DC    3AL.4(1)
B8       DC    AL.12(1),AL2(3)
B9       DC    AL.4(1),C'A',AL.4(2)
BA       DS    AL.12,AL.4
BB       DC    X'FF'
C1       DC    AL1(1)
C2       DC    XL1'F'
C3       DC    AL2(1)
C4       DC    CL3'AB'
C5       DC    F'7'
         END
