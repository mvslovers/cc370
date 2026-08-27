* issue #53 (step 2) -- 65 nominal values in one operand, over three cards.
* A guard against the #50 defect reappearing inside #53's own fix: the operand
* splitter drops everything past its maximum without a diagnostic, and the
* value-list cap used to be 64. A dropped nominal value is worse than a dropped
* EXTRN symbol -- its storage is never reserved, so the location counter
* under-advances at RC 0 and every later symbol in the section shifts, which is
* the defect this issue exists to close.
* 65 one-digit packed constants of one byte each: the section must be 65 bytes.
T        CSECT
D1       DC    P'0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,X
               7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,X
               5,6,7,8,9,0,1,2,3,4'
         END
