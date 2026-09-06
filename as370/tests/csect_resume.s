* Resuming a control section.  Each section carries its OWN location
* counter: a resumed CSECT continues where THAT section left off, not
* where the assembly as a whole left off.
*
* Measured against IFOX00 on MVS/CE:
*   A   SD  ADDR 000000  LENGTH 000006   (4 bytes + the resumed 2)
*   B   SD  ADDR 000008  LENGTH 000008
* and the resumed DC lands at LOC 000004 -- back inside A, not after B.
*
* as370 ran one continuous counter for every section, so A came out
* LENGTH 000012 with its resumed text at 000010, overlapping B.
* Nothing in the ecosystem corpus resumes a section, so the
* byte-identity gate could not see it.  The TSO parse macros
* (IKJPARM/IKJKEYWD/...) do it dozens of times per module through
* "&SYSECT CSECT ," and that is where it surfaced.
A        CSECT
         DC    C'AAAA'
B        CSECT
         DC    C'BBBBBBBB'
A        CSECT
         DC    C'aa'
         END
