         COPY  PDPTOP
         CSECT
* X-var _FltMax
         ENTRY @FLTMAX
* Program data area
         DS    0F
@FLTMAX  EQU   *
         DC    X'7FFF'
         DC    X'FFFF'
         DC    X'FFFF'
         DC    X'FFFF'
         END
