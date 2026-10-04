         COPY  PDPTOP
         CSECT
* X-var __doperm
         ENTRY @@DOPERM
* Program data area
         DS    0F
@@DOPERM EQU   *
         DC    F'0'
         END
