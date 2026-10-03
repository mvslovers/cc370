* cc370#272: IFOX00 holds an expression outside conditional assembly
* to 20 terms; the 21st is IFO168 at severity 8 and the value is 0
* (xeval SYNERR9). Measured: 50 terms -> IFO168 and zero under IFOX00
* (#272), and IGG0CLB9's 20 terms assemble clean. 21 terms, with and
* without parentheses (a parenthesis is not a term), follow the source.
* A SETA is not bounded and must stay clean.
T        CSECT
T50      DC    A(1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+X
               1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1)
T20      DC    A(1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1)
T21      DC    A(1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1)
T21P     DC    A(1+1+1+1+1+1+1+1+1+1+(1+1+1+1+1+1+1+1+1+1+1))
         LCLA  &N
&N       SETA  1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+X
               1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1+1
TN       DC    A(&N)
         END
