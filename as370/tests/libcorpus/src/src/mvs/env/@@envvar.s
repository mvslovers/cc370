         COPY  PDPTOP
         CSECT
* X-var __envvar
         ENTRY @@ENVVAR
* Program data area
         DS    0F
@@ENVVAR EQU   *
         DC    F'0'
* X-var __envsiz
         ENTRY @@ENVSIZ
         DS    0F
@@ENVSIZ EQU   *
         DC    F'0'
         END
