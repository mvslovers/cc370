         COPY  PDPTOP
         CSECT
* X-var __perm
         ENTRY @@PERM
* Program data area
         DS    0F
@@PERM   EQU   *
         DC    X'00'
         DC    X'00'
         DC    X'00'
         DS    XL5
         DS    XL184
         DS    XL384
         END
