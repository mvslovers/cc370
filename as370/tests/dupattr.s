* A forward symbol after an attribute in a duplication factor (#473).
*
* IFOX00 flags X IFO231 + IFO206 at rc 8 and H reserves nothing,
* so Y is at 000008 and the section is 9 bytes long (MVSTK5-REF
* JOB00272, listing only).  No IFO217: the undefined X counts as
* an absolute 0 and L'G is absolute, so nothing is relocatable.
* as370 used to skip X inside a string opened by the ' of L'G,
* assemble at rc 0 and reserve L'G+X = 10 bytes, putting Y at
* 000012 -- every later symbol shifted.
PRBDUP   CSECT
G        DS    CL8
H        DS    (L'G+X)C
Y        DC    C'Y'
X        EQU   2
         END   PRBDUP
