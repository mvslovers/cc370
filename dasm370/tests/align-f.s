* cc370#385's acceptance, the candidate both references diff
* against: the two bytes at 000006 are COVERED here.
*
* Against `align-d.s' the owning statement only aligned over them;
* against `align-e.s' it reserved them.  Same offset, same bytes,
* same finding -- opposite verdicts.
*
ALIGND   CSECT
         BALR  12,0
         USING *,12
         L     2,VAL
         DC    XL2'FFFF'
         BR    14
VAL      DC    F'1'
         END
