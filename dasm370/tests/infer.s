* cc370#382 PR C: the three evidence kinds --infer can produce.
*
* R12 is a PROLOGUE base -- BALR 12,0 says exactly where and
* nothing about for how long.  R9 is an RLD base: it is loaded
* from an address constant the relocation dictionary resolves
* into this section, which is the one place an object-deck
* reader has ground truth.  R7 is a PATTERN: the code addresses
* through it and nothing here says where it points.
*
* Keep every line under column 72.
*
INFER    CSECT
INFENT   BALR  12,0
         USING *,12
         L     9,APTR                 an A-con into this section
         L     3,0(0,9)               and R9 used as a base
         ST    3,4(0,9)
         L     4,8(0,7)               R7: used, origin unknown
         BR    14
         DS    0F
APTR     DC    A(TARGET)
TARGET   DC    F'1'
         DC    F'2'
         END   INFENT
