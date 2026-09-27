* An attribute apostrophe in a machine-instruction operand is not
* a quote (#465).
*
* scan_undef_terms() -- the IFO188 scan that zeroes a machine
* instruction naming an undefined symbol -- toggled its string
* state on every apostrophe.  After L'G the rest of the operand
* read as the inside of a string, the literal's own opening quote
* closed it, and the literal's TEXT was scanned as symbols: AB
* and ABCD were "undefined", rc 8, and both MVCs were zeroed.
*
* 1  L'G, then a literal with a blank inside it.
* 2  L'G, then a literal with the blank at its end.
* 3  Control: the same offset with L'G spelled out as 8.  It never
*    touched the defect, so it must assemble identically on both
*    binaries -- a fix that disturbs the rest of the scan shows
*    here.
*
* IFOX00 (MVSTK5-REF JOB00270) assembles all three: D204 F01E F030,
* D204 F01E F035, D204 F01E F030.  Its rc is 4, from IFO229 alone
* (possible reenterability error -- each MVC stores into its own
* CSECT), which is not what this fixture is about.  The pre-fix
* as370 scores rc 8 and zeroes cards 1 and 2.
*
ATTRUND  CSECT
         USING ATTRUND,15
         MVC   F+1+L'G+3(5),=C'AB CD'
         MVC   F+1+L'G+3(5),=C'ABCD '
         MVC   F+1+8+3(5),=C'AB CD'
F        DS    CL20
G        DS    CL8
         END   ATTRUND
