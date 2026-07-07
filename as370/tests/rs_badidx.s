RSBAD    CSECT
* RS-format storage operands written RX-style with an empty index field.
* There is no index field on an RS operand, so IFOX00 rejects this
* (ERR216 ILLEGAL OPERAND FORMAT, severity 12). as370 must reject it too,
* not silently assemble it with base 0 (an absolute low-core reference).
         LM    0,12,20(,13)
         STM   14,12,12(,13)
         END   RSBAD
