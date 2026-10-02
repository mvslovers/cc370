* T' of a macro parameter follows what was WRITTEN at the call (#333).
* Measured on MVSTK5-REF (the issue's table): an argument written as a
* SET variable -- local or global, SETA or SETC -- gives U; a literal,
* or the caller's own parameter passed along, keeps its value's N.
* Every argument substitutes to the same 6. Expected: U N N U U U.
         MACRO
         INNER &P
         LCLC  &T
&T       SETC  T'&P
         DC    C'&T'
         MEND
         MACRO
         OUTER &FROM
         GBLA  &GA
         GBLC  &GC
         LCLA  &A
         LCLC  &C
&A       SETA  6
&C       SETC  '6'
&GA      SETA  6
&GC      SETC  '6'
         INNER &A
         INNER 6
         INNER &FROM
         INNER &C
         INNER &GA
         INNER &GC
         MEND
TSETARG  CSECT
         OUTER 6
         END
