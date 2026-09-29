* L' of a forward symbol in an EQU, a value and a length (#494,
* #497).
*
* IFOX00 (MVSTK5-REF JOB00277, rc 8): LEN EQU L'FWD is IFO231 and
* 0; DC AL1(L'FWD) is 05 before and after FWD; W DC CL(L'FWD)'W'
* is IFO231 + IFO179 and assembles nothing; Z DC CL(L'FWD)'Z',
* after FWD, is E940404040.  as370 lost the 'Z' (#497) and took
* LEN and W as if FWD were defined (#494).
*
* The deck in tests/ref/attrfwd.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBFWD   CSECT
LEN      EQU   L'FWD
C        DC    AL1(LEN)
V        DC    AL1(L'FWD)
W        DC    CL(L'FWD)'W'
Y        DC    C'Y'
FWD      DS    CL5
X        DC    AL1(L'FWD)
Z        DC    CL(L'FWD)'Z'
         END   PRBFWD
