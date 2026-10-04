         COPY  PDPTOP
         CSECT
* X-var __stdin
         ENTRY @@STDIN
* Program data area
         DS    0F
@@STDIN  EQU   *
         DC    V(@@PERM)
         END
