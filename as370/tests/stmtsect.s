* cc370#411: the two-section case, because one section at origin 0
* cannot test the columns that exist for two.
*
* `stmtexp.s' has a single CSECT at 0, so subtracting secorg from
* loc is a no-op there and a consumer that ignores secorg entirely
* passes on it.  Here SECTA is opened, LEFT, and RESUMED -- so the
* counter continues where SECTA left off while SECTB has its own
* origin, and the section-relative offset an object deck carries is
* loc - secorg for both.
*
* The deck is the oracle: run.sh reads the ESD origins and the TXT
* cards and requires every column to agree with them.
*
* Keep every line under column 72.
*
SECTA    CSECT
         DC    XL2'AABB'
SECTB    CSECT
         DC    XL2'CCDD'
SECTA    CSECT
         DC    XL1'EE'
         END
