* Both shapes --sparse-text must tell apart, in one module.
* A DS reservation is covered by no TXT card, so a module may
* legitimately omit it.  DC zeros ARE text -- a programmer wrote
* them -- and must survive however many of them are zero.
* In the loaded module the two regions are identical bytes; only
* the object deck tells them apart.  That is why a predicate
* reading byte values drops both, which is what #445 did.
* Markers bracket each region so a wrongly elided record shows up
* as a missing marker, not only as a smaller file.
SPARSE   CSECT
         BR    14
HEADMK   DC    C'HEADMARK'
         DS    XL32767                 reserved: no TXT card here
         DS    XL32767
MIDMK    DC    C'MIDMARK!'
         DC    32767X'00'              written zeros: these are text
         DC    32767X'00'
TAILMK   DC    C'TAILMARK'
         END
