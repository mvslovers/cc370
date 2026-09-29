* An attribute inside a literal, then an undefined symbol (#184),
* and the undefined symbol after L' in a DC (#474).
*
* IFOX00 (MVSTK5-REF JOB00275, rc 8) flags NOSUCH IFO188 on all
* three statements, zeroes BOTH CLCs and assembles LEN as 0000.
* as370 used to open a string on the ' of L'G inside =A(L'G), so
* the first CLC was assembled (#184).  The second CLC is the
* control: the same statement without L', always zeroed.  LEN is
* still 0001 with no diagnostic on as370 (#474, blocked on #494),
* so tests/run.sh compares only the CLC bytes for now.
*
* The deck in tests/ref/litattr.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBL184  CSECT
         USING PRBL184,15
         CLC   =A(L'G),NOSUCH
         CLC   =A(G),NOSUCH
LEN      DC    AL2(L'NOSUCH)
G        DS    CL8
         END   PRBL184
