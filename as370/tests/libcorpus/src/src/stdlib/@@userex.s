         COPY  PDPTOP
         CSECT
* X-var __userex
         ENTRY @@USEREX
* Program data area
         DS    0F
@@USEREX EQU   *
         DC    F'0'
         DS    XL124
         END
