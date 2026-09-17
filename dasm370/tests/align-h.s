* cc370#385: the candidate side of `align-g.s'.
*
* The MVI's immediate is 129 here and 128 there, so the one finding
* is at 000008 -- inside the range the bare ORG claims and outside
* anything the ORG wrote.
*
ORGX     CSECT
         ENTRY OVERMVI
         BALR  12,0
         USING *,12
         BR    14
         L     2,0(0,12)
         L     3,0(0,12)
         ORG   *-8
         ST    2,0(1,0)
OVERMVI  MVI   0(1),129
         ORG   *-8
         DC    X'77'
         ORG
         BR    14
         END
