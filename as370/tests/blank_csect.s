* Does a LITERAL blank CSECT card RESUME the private code's counter
* or RESTART it at zero? cc370#290's oracle settled it only for a
* REJECTED NAMED section (it resumes, LOC 000004). The modules that
* would answer it for the blank card are the &CSECT family -- IFCE*
* and IFCS*, where the name substitutes to nothing -- and their
* IFOX00 references come from rc 12 runs, so they cannot arbitrate.
*
* Predictions, written down before the oracle was asked:
*   RESUME   PC is 12 bytes. TXT at 0 = C1, at 4 = C2, at 8 = C3.
*            A is chained after it at x'10' (12 rounded up).
*   RESTART  PC is 4 bytes. Three TXT records all at address 0,
*            each overwriting the last. A is chained at x'8'.
* The two differ in the ESD length AND in the TXT addresses, so no
* single byte decides it alone.
*
* as370 today does NEITHER, and the fixture found that rather than
* the author: measured on 0a6e868 it RESTARTS on the first blank
* card and RESUMES on every later one --
*   PC is 8 bytes; TXT C1 at 0, C2 at 0 (overwriting C1), C3 at 4.
* That is `opened' deciding: the first blank CSECT statement reads
* ++opened == 1 and resets the section's counter, the second reads 2
* and does not. A first blank card and a second cannot both be right,
* so this is a defect whichever way IFOX00 answers -- the oracle
* decides WHICH of the two as370 behaviours to keep, not whether
* there is something to fix.
* It is also why the fixture carries TWO blank cards. With one it
* would have read as a clean RESTART and proved the wrong thing.
*
* Control, true under both rules: A is an ordinary named section
* opened once and resumed once, so its two pieces must sit at its
* own 0 and 4. If they do not, the fixture is measuring something
* other than what it says.
         DC    XL4'C1C1C1C1'      implicit private code, no CSECT yet
A        CSECT
         DC    XL4'AAAAAAAA'
         CSECT                    blank name: resume, or restart?
         DC    XL4'C2C2C2C2'
A        CSECT                    the control, resumed
         DC    XL4'A2A2A2A2'
         CSECT                    and the blank one again
         DC    XL4'C3C3C3C3'
         END
