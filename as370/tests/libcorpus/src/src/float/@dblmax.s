         COPY  PDPTOP
         CSECT
* X-var _DblMax
         ENTRY @DBLMAX
* Program data area
         DS    0F
@DBLMAX  EQU   *
         DC    X'7FFF'
         DC    X'FFFF'
         DC    X'FFFF'
         DC    X'FFFF'
         END
