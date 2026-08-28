* issue #50 -- the one-ENTRY-per-line spelling of entry_list.s (the
* workaround
* the reporter used). This form has always assembled; it is the oracle
* for the
* list form, since single-symbol ENTRY is pinned to IFOX00 by
* sample2/3/7.
COBMOD   CSECT
         ENTRY COBDISP
         ENTRY COBTERM
         ENTRY COBWRL
         ENTRY COBDATE
COBDISP  BR    14
COBTERM  BR    14
COBWRL   BR    14
COBDATE  BR    14
         END
