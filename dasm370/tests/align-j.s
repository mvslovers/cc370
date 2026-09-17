* cc370#385: the candidate side of `align-i.s'.
*
* The two bytes X'1812' are gone and the two DS statements are one
* `BUF DS CL8'.  The bytes are otherwise identical, so the single
* finding is a DELETE whose candidate offset is 000008 -- inside
* that card rather than at its start.
*
SPLITX   CSECT
         BALR  12,0
         USING *,12
         BR    14
         DC    XL2'5800'
BUF      DS    CL8
         BR    14
         END
