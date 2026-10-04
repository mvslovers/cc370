         COPY  PDPTOP
         CSECT
* X-var _DblMin
         ENTRY @DBLMIN
* Program data area
         DS    0F
@DBLMIN  EQU   *
         DC    X'0010'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         END
