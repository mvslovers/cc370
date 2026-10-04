         COPY  PDPTOP
         CSECT
* X-var __stderr
         ENTRY @@STDERR
* Program data area
         DS    0F
@@STDERR EQU   *
         EXTRN @@PERM
         DC    A(@@PERM+384)
         END
