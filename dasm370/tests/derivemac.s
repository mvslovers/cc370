* cc370#382 PR B: the -I acceptance. PAD comes from a macro library
* and expands to a different LENGTH in maclib-a and maclib-b, so every
* label after it sits at a different offset. A hint set derived against
* the wrong library is a wrong hint set that looks entirely right --
* which is why the derived file records the -I list it was built with.
*
DERMAC   CSECT
DMENT    BALR  12,0
         USING *,12
         PAD
AFTER    L     2,VALUE
         BR    14
VALUE    DC    F'7'
         END   DMENT
