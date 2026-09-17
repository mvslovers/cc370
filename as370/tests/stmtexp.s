* cc370#411: what --stmts must be able to say and a listing cannot.
*
* RESERVE vs ALIGN is the field this export exists for.  In an
* OBJECT a `DS 0F' pad and a `DS CL1' reservation are both bytes
* no TXT card covers, and two defensible object-side rules were
* measured to disagree 1 % against 14 % about the size of that
* population.  Only the source knows, and only at assembly time.
*
* The macro is expanded TWICE so mcall_stmt tells the two calls
* apart -- a listing marks both `+' and names neither.
*
* Three more properties are pinned here because #385's translator
* reads this export and a wrong reading of any of them produces an
* edit that assembles and is wrong:
*
*   len is the LOCATION COUNTER ADVANCE and not the bytes emitted.
*   BR 14 at an odd offset forces an alignment byte, so its len is
*   3 and its first byte is the pad.  The listing agrees: it shows
*   the pad at the statement's own LOC and the halfword after it.
*
*   len is NEGATIVE where the counter moves BACK.  An ORG is a
*   statement like any other and its advance is its own.  Corpus:
*   59,443 records with len < 0 in 3,758 of 5,528 modules.
*
*   org is the OUTERMOST open-code call, mcall_name the INNERMOST
*   macro.  At depth 2 the inner call card is a model card in a
*   library and is in no file the caller can edit; org still names
*   one that is.  20.3 % of generated records are at depth >= 2.
*
* Keep every line under column 72.
*
         MACRO
&L       PADPAIR &N
&L       DS    0F
         DS    CL&N
         MEND
         MACRO
&L       INNER &N
&L       DS    CL&N
         MEND
         MACRO
&L       OUTER &N
&L       INNER &N
         MEND
STMTX    CSECT
A        DS    CL1
B        DS    0F
C        DC    F'1'
FIRST    PADPAIR 1
SECOND   PADPAIR 3
         BR    14
DEEP     OUTER 2
TBL      DC    F'0'
         DC    F'0'
         ORG   TBL
OVER     DC    X'FF'
         ORG   ,
         END
