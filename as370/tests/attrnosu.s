* The symbol after an attribute prefix is an ordinary term (#465).
*
* IFOX00 flags the undefined NOSUCH IFO188 and zeroes the whole
* instruction (MVSTK5-REF JOB00271, rc 8).  as370 used to read
* NOSUCH as part of a string opened by the apostrophe of L' and
* assembled MVC 7(5,15),6(15) at rc 0 -- L'NOSUCH taken as 1.
*
* The deck in tests/ref/attrnosu.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
PRBNOSU  CSECT
         USING PRBNOSU,15
         MVC   F+L'NOSUCH(5),F
F        DS    CL20
         END   PRBNOSU
