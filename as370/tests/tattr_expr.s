* cc370 -- T' of an EXPRESSION answers with the type of its
* LEFTMOST TERM, the rule L' already had.  GOIF1 (APVTMACS)
* branches on  AIF (T'&C NE 'U')  and picks CLI over CLC when
* it gets 'U', which moves every branch target after it.
*
* Controls are inside the fixture: the bare symbol beside the
* expression, and an absolute EQU whose type IS 'U' -- so a
* version that simply answered "not U" everywhere fails too.
         MACRO
         SHOW  &C
         AIF   (T'&C EQ 'U').ISU
         MNOTE 0,'&C -> nicht U'
         MEXIT
.ISU     MNOTE 0,'&C -> U'
         MEND
TATTR    CSECT
LNCNT    DS    H
D2       EQU   2
         SHOW  LNCNT
         SHOW  LNCNT+D2
         SHOW  D2
         SHOW  D2+1
         END
