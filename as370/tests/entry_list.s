* issue #50 -- ENTRY with a comma-separated symbol list.
* The shape a COBOL compiler emits for its runtime entry points; IFOX00 accepts
* it and produces one LD per symbol. as370 used to take the whole operand as a
* single symbol name, so the >8-character external-symbol check fired on
* "COBDISP,COBTERM,COBWRL,COBDATE" and the module would not assemble.
* Paired with entry_list_1pl.s -- the one-ENTRY-per-line spelling of the same
* module, which always assembled correctly and is the form the IFOX-pinned
* corpus already covers. The two decks must be byte-identical.
COBMOD   CSECT
         ENTRY COBDISP,COBTERM,COBWRL,COBDATE
COBDISP  BR    14
COBTERM  BR    14
COBWRL   BR    14
COBDATE  BR    14
         END
