* cc370#382 PR C: the three evidence kinds --infer can produce.
*
* R12 is a PROLOGUE base -- BALR 12,0 says exactly where and
* nothing about for how long.  R9 is an RLD base: it is loaded
* from an address constant the relocation dictionary resolves
* into this section, which is the one place an object-deck
* reader has ground truth.  R7 is a PATTERN: the code addresses
* through it and nothing here says where it points.  R5 carries a
* BALR and is never used as a base at all -- reported, because it
* happened, but not claimed as a prologue.
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
         L     6,0(0,1)               R1 used as a base, so the
*                                     phantom below reads as prologue
         BR    14
* R5 gets a BALR and is never used as a base: not a prologue,
* however much it looks like one.
         BALR  5,0
* BALR 1,15 has R2 = R15, so it is a call and not the idiom; the
* R2 == 0 guard excludes it and this pins that.
         BALR  1,15
         DS    0F
* Two phantoms, one mechanism: data that reads as BALR 1,0 to
* anything working from bytes.  Only reachability (#383) can say
* nothing branches there.
*
* DECPHAN is the instructive one and it is the real case.  ICKTR02
* carries DC F'01296' -- and decimal 1296 is X'00000510', so the
* low half of an ordinary fullword constant IS the idiom.  Nobody
* reading that card would suspect it.  The hex form below is the
* same mechanism written where a reader might look for it.
DECPHAN  DC    F'1296'
PHANTOM  DC    X'05100000'
APTR     DC    A(TARGET)
TARGET   DC    F'1'
         DC    F'2'
         END   INFENT
