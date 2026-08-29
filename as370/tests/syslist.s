* &SYSLIST(n,m): the second subscript reaches an element INSIDE a
* sublist operand (issue #94). Operand 1 is a three-element sublist,
* operand 2 is not a sublist at all -- so the m=1 and m>1 cases on a
* plain operand are probed too, as is the named-parameter form &P(m)
* that already worked.
         MACRO
&NAME    SUBL  &P1,&P2
         LCLA  &E12
         LCLC  &E11,&E13,&F21,&F22,&NP
&E11     SETC  '&SYSLIST(1,1)'
&E12     SETA  &SYSLIST(1,2)
&E13     SETC  '&SYSLIST(1,3)'
&F21     SETC  '&SYSLIST(2,1)'
&F22     SETC  '&SYSLIST(2,2)'
&NP      SETC  '&P2(1)'
&E11     EQU   &E12
E13      DC    C'/&E13/'
F21      DC    C'/&F21/'
F22      DC    C'/&F22/'
NAMED    DC    C'/&NP/'
         MEND
SYSLTEST CSECT
         SUBL  (ALPHA,8,GAMMA),BETA
         END
