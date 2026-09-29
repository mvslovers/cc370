* An attribute in a macro subscript: &SYSLIST(N'&SYSLIST,2).
*
* IFOX00 (MVSTK5-REF JOB00280, rc 0): every pair below assembles
* the same bytes, the attribute form and its numeric control --
* 22,22,22 and 33,33 and 2,2.  as370 toggled a string open on the
* ' of N', lost the second subscript and returned the whole
* third operand: SETA 0 and AL1((11,22,33)).
*
* The deck in tests/ref/vrefattr.obj was captured from these
* statements without this comment block; comments add no object
* text, so the deck is the same.
         MACRO
&L       MYM   &A
         LCLA  &I,&J,&K
&I       SETA  &SYSLIST(N'&SYSLIST,2)
&J       SETA  &SYSLIST(3,2)
&K       SETA  &SYSLIST((N'&SYSLIST),2)
&L       DC    AL1(&I,&J,&K)
         DC    AL1(&SYSLIST(N'&SYSLIST,3))
         DC    AL1(&SYSLIST(3,3))
         DC    AL1(&SYSLIST(N'&SYSLIST-1))
         DC    AL1(&SYSLIST(2))
         MEND
PRBVREF  CSECT
V        MYM   1,2,(11,22,33)
         END   PRBVREF
