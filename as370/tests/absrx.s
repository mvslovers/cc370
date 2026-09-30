* cc370#342, the RX half: an operand written S(X) -- an index and no
* base -- whose displacement is ABSOLUTE, under an ABSOLUTE USING.
* Does the USING supply the base, as it does for the same operand
* without the index (#190) and for an SS length subscript (absssub)?
* No MVSBLD module carries the shape; this asks the oracle directly.
*
* Two rules, and the fixture separates them per line:
*   H1  the index form resolves through the absolute USING too
*   H0  an index form keeps base 0 (as370 before this probe)
* and a third shape in which the symbol form and the numeric form
* differ, which is why both are written.
*
*                               H1           H0
*   R1 LA 1,FLD(3)  symbolic    4113 2100    4113 0100
*   R2 L  4,8(5)    numeric     5845 2008    5845 0008
*   R3 LA 6,FLD     no index    4160 2100    4160 2100  control
*   R4 LA 7,FLD(3)  after DROP  4173 0100    4173 0100  control
* The relocatable USING *,15 must never serve an absolute operand.
T        CSECT
         USING *,15
DUM      EQU   0
FLD      EQU   DUM+256
         USING DUM,2
R1       LA    1,FLD(3)
R2       L     4,8(5)
R3       LA    6,FLD
         DROP  2
R4       LA    7,FLD(3)
         END
