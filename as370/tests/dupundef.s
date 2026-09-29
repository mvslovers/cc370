* Undefined and forward symbols in a duplication factor, a bit
* length and an ORG (#494, #500).
*
* IFOX00 (MVSTK5-REF JOB00279, rc 8): D1-D3 are IFO188 + IFO206,
* no IFO231, and reserve nothing; B1 is IFO188 + IFO179, B2 is
* IFO231 + IFO179, neither assembles anything; ORG *+L'FWD is
* IFO231 and moves nothing, so H is at 000005 and A(H) is 5.
*
* The deck in tests/ref/dupundef.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBD     CSECT
D1       DS    (NOSUCH)C
M1       DC    C'1'
D2       DS    (L'NOSUCH)C
M2       DC    C'2'
D3       DS    (NOSUCH+2)C
M3       DC    C'3'
B1       DC    BL.(L'NOSUCH)'1'
M4       DC    C'4'
B2       DC    BL.(L'FWD)'1'
M5       DC    C'5'
         ORG   *+L'FWD
H        DC    C'H'
AH       DC    A(M5,H)
FWD      DS    CL5
         END   PRBD
