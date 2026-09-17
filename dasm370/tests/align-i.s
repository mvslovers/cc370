* cc370#385: an INSERTION POINT NEED NOT FALL ON A SOURCE BOUNDARY,
* and `chosen: "encloses"' is what says so.
*
* A disassembly's statement boundaries are the DECODER's, not the
* assembler's.  Here the two bytes X'5800' and the first two bytes
* of the DS after them decode together as one four-byte `L 0,0(0,0)'
* -- so the decoder's next boundary is 000008 while the candidate's
* `BUF DS CL8' runs 000006..00000D.  A zero-length deletion point
* lands at 000008, two bytes INSIDE that card, and the card has to
* be SPLIT.  Nothing else in the record would say so: a bare absence
* reports only that nothing was found.
*
* THE PROPERTY THAT MAKES THE CASE IS length == 0, NOT "inside", and
* that is measured rather than reasoned.  Over the 832: 170 encloses
* in 63 modules, every one length 0; 2,168 findings of non-zero
* length ALSO start inside their chosen statement and are correctly
* `reserving' or `unreserved'.  The separation is exact in both
* directions.  A fixture pinning "the offset is inside a statement"
* would pass on any of those 2,168 and prove nothing -- which is why
* three earlier attempts at this fixture failed: they pinned
* "inside" and the alignment kept handing back an ordinary data
* change.  Measured by mvs38src; the real-material witness is
* ICBVUT01, a delete at 22030 inside `GROUPKY DS CL8' at 22027.
*
* `align-j.s' is this file with the two bytes removed, so the one
* finding is a DELETE and the candidate side of it is that point.
*
* Keep every line under column 72.
*
SPLITX   CSECT
         BALR  12,0
         USING *,12
         BR    14
         DC    XL2'5800'
BUF      DS    CL2
         DC    XL2'1812'
BUF2     DS    CL6
         BR    14
         END
