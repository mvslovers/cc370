* A bit length in parentheses that uses an attribute (#497).
*
* IFOX00 (MVSTK5-REF JOB00278, rc 0) assembles B as 80 and X as
* ABC0.  as370 toggled a string open on the ' of L'F, never found
* the closing parenthesis and lost the nominal value: 00, 0000.
*
* The deck in tests/ref/bitattr.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBBIT   CSECT
F        DS    CL1
B        DC    BL.(L'F)'1'
B7       DC    BL.7'1'
G        DS    CL3
X        DC    XL.(L'G*4)'ABC'
X12      DC    XL.12'ABC'
         END   PRBBIT
