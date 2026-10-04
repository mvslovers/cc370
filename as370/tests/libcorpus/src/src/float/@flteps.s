         COPY  PDPTOP
         CSECT
* X-var _FltEps
         ENTRY @FLTEPS
* Program data area
         DS    0F
@FLTEPS  EQU   *
         DC    X'3C10'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         END
