         COPY  PDPTOP
         CSECT
* X-var _DblEps
         ENTRY @DBLEPS
* Program data area
         DS    0F
@DBLEPS  EQU   *
         DC    X'3410'
         DC    X'0000'
         DC    X'0000'
         DC    X'0000'
         END
