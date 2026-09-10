* cc370 -- the END literal pool belongs to the first control
* section and is measured from ITS extent, never from the
* location counter that happens to be current.
*
* IFDOLT39 has one named section, then DPRCOM DSECT, then a
* bare CSECT card while the DSECT is STILL CURRENT.  as370
* reserved the pool at the DSECT's counter, so the section came
* out as long as the DSECT -- 0xb6c against IFOX00's 0xa0c, and
* all three IFDOLT modules ended at ~0xB80, which is DPRCOM's
* size and not their own.
*
* Control inside the fixture: the L must reach the literal at a
* displacement inside DPC, not one inside the DSECT.
DPC      CSECT
         USING DPC,15
         L     1,=X'00FFFFFF'
         DC    XL8'00'
DPRCOM   DSECT
         DS    XL256
ENDCOM   EQU   *
         CSECT
         END
