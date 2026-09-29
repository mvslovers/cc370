* L' of an undefined or forward symbol in a length, an EQU and a
* duplication factor (#494).
*
* IFOX00 (MVSTK5-REF JOB00276, rc 8): A DS CL(L'NOSUCH) is IFO188
* + IFO179 and reserves nothing; LEN EQU L'NOSUCH is IFO188 and 0;
* D DS (L'NOSUCH)C is IFO188 + IFO206; F DS CL(L'FWD) is IFO231 +
* IFO179 and reserves nothing although FWD is defined later.
*
* The deck in tests/ref/lenundef.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBLEN   CSECT
A        DS    CL(L'NOSUCH)
B        DC    C'B'
LEN      EQU   L'NOSUCH
C        DC    AL1(LEN)
D        DS    (L'NOSUCH)C
E        DC    C'E'
F        DS    CL(L'FWD)
H        DC    C'H'
FWD      DS    CL5
         END   PRBLEN
