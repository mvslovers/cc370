         COPY  PDPTOP
         CSECT
* Program data area
         DS    0F
@V1      EQU   *
         DC    F'0'
         DC    F'0'
         DC    A(@V2)
         DC    V(@@75GABN)
         DC    V(@@75GHBN)
         DC    V(@@75SOCK)
         DC    V(@@75BIND)
         DC    V(@@75CONN)
         DC    V(@@75LIST)
         DC    V(@@75ACCE)
         DC    V(@@75SEND)
         DC    V(@@75RECV)
         DC    V(@@75CLOS)
         DC    V(@@75IOCT)
         DC    V(@@75SNAM)
         DC    V(@@75SELE)
         DC    V(@@75SELX)
         DC    V(@@75PNAM)
         DC    V(@@75GHBA)
* X-var __75vect
         ENTRY @@75VECT
         DS    0F
@@75VECT EQU   *
         DC    A(@V1)
         DS    0F
@V2      EQU   *
         DS    XL128
         END
