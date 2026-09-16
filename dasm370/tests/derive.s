* cc370#382 PR B: a source with enough structure for --derive-hints
* to have something to derive -- named offsets, a base register with
* a real lifetime, and a DSECT domain that cannot become a [[base]].
*
* Keep every line under column 72.
*
DERIVE   CSECT
         ENTRY DERENT
DERENT   BALR  12,0
         USING *,12
         LA    1,0(0,0)
LOOPTOP  L     2,COUNTER
         S     2,ONE
         ST    2,COUNTER
         BNZ   LOOPTOP
         USING MYDSECT,9        a DSECT domain: not a [[base]]
         L     3,MYWORD
         DROP  9
FINISH   BR    14
         DS    0F
COUNTER  DC    F'10'
ONE      DC    F'1'
TABLE    DC    X'0102030405060708'
MYDSECT  DSECT
MYWORD   DS    F
MYCHAR   DS    CL8
         END   DERENT
