         COPY  PDPTOP
         CSECT
* X-var __stdout
         ENTRY @@STDOUT
* Program data area
         DS    0F
@@STDOUT EQU   *
         EXTRN @@PERM
         DC    A(@@PERM+192)
         END
