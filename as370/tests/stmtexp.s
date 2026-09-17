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
* Keep every line under column 72.
*
         MACRO
&L       PADPAIR &N
&L       DS    0F
         DS    CL&N
         MEND
STMTX    CSECT
A        DS    CL1
B        DS    0F
C        DC    F'1'
FIRST    PADPAIR 1
SECOND   PADPAIR 3
         BR    14
         END
