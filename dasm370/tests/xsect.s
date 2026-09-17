* cc370#418: an address constant naming ANOTHER SECTION of the same
* deck carries that section's origin twice.
*
* A deck numbers module-absolute throughout (cc370#415), so an adcon
* pointing at a sibling holds THAT SECTION'S ORIGIN plus the offset
* into it.  The disassembly must print the offset alone.
*
* AHLMCER is the worked case: the TXT at X'4A4' holds 00000548 and
* AHLMCMSG's origin is X'548', so the target is AHLMCMSG+0 and the
* old output `A(AHLMCMSG+X'548')' landed 1,352 bytes past it.
*
* THE FIRST SECTION IS THE NULL CONTROL.  An adcon into a section at
* ORIGIN 0 reads the same either way -- subtracting nothing changes
* nothing -- which is exactly why this survived: 131 of the 814
* cross-section RLD entries over the corpus point at such a section
* and were always right.  A fixture with only the non-zero case
* would pass on a rule that subtracted the WRONG origin.
*
* So XSECTB points BACK into XSECTA, which is at origin 0: BACKZERO
* and BACKOFF must read exactly as they did before the fix, while
* XSECTA's two adcons into XSECTB must both lose X'10'.
*
* Keep every line under column 72.
*
XSECTA   CSECT
FIRST    DC    XL4'AAAAAAAA'
PZERO    DC    A(FIRST)
PLATE    DC    A(LATE)
PMID     DC    A(MIDDLE)
XSECTB   CSECT
LATE     DC    XL4'BBBBBBBB'
MIDDLE   DC    XL4'CCCCCCCC'
BACKZERO DC    A(FIRST)
BACKOFF  DC    A(PLATE)
         END
