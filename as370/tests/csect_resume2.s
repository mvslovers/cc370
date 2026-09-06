* Which counter fixes a section's ORIGIN?
*
* In csect_resume.s A's open-time counter (4) and A's final length (6)
* both round to 8, so B at 000008 cannot tell the two rules apart.
* Here the resumed A grows to 16 -- past B's origin -- so the rules
* disagree and the oracle decides:
*
*   B ADDR 000008 -> the origin is the counter as it stood when B was
*                    opened, and sections may overlap in the listing
*   B ADDR 000010 -> origins come from the FINAL section lengths, so
*                    they are assigned after the whole assembly is seen
A        CSECT
         DC    C'AAAA'
B        CSECT
         DC    C'BBBBBBBB'
A        CSECT
         DC    C'0123456789AB'
         END
