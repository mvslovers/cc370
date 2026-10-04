         COPY  PDPTOP
         CSECT
* X-var _FltMin
         ENTRY @FLTMIN
* Program data area
         DS    0F
@FLTMIN  EQU   *
         DC    X'0010'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         END
