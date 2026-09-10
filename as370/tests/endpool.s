* cc370 -- the END literal pool goes behind the first control
* section's FINAL extent.  as370 reserved its room when the
* second section opened and never moved it.
*
* The resume below adds only TWO bytes, which is LESS than the
* four the pool reserved.  That is AMDPRUIM's shape and it is
* the strict case: the section's own growth stays under the
* reserved pool's end, so "has it grown?" cannot be answered
* from the extent the reservation itself raised.
*
* Control inside the fixture: TWOB's object code must survive
* -- if the pool is placed at the old mark it lands on top of
* it -- and the L must reach the literal.
LTA      CSECT
         USING LTA,15
         DC    XL16'00'
SEC2     CSECT
         DC    XL8'00'
LTA      CSECT
TWOB     DC    XL2'ABCD'
         L     1,=X'00FFFFFF'
         END
