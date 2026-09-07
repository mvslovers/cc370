* A relocatable EQU belongs to the section of its VALUE, not to the
* section the EQU card happens to sit in (#154).
*
* PL/S output puts every EQU at the end of the module, after the
* mapping macros have left a DSECT current.  An EQU naming a CSECT
* label there is still a CSECT address.
*
*   Wert-Sektion   (IFOX00)  -> B TGTALIA == B CTLALIA -> 47F0 C00C
*   Karten-Sektion (as370)   -> Basis aus MAPDS' USING   -> 47F0 B00E
*
* Die falsche Variante ist hier die STILLE: R11 deckt MAPDS,
* also findet using_for eine Basis und schweigt bei rc 0.  Ohne
* die zweite USING gibt es stattdessen IFO209 (BLSCCLSE).
*
* CTLALIA is the control: same equate, card in the CSECT itself.
* MOFF is the second control: an ABSOLUTE equate under the DSECT
* stays absolute and must keep addressing through R11.
ADDRQ    CSECT
         BALR  12,0
PSTART   DS    0H
         USING PSTART,12
         USING MAPDS,11
         B     TGTALIA
         B     CTLALIA
         L     1,MOFF(,11)
TARGET   DS    0H
         BR    14
CTLALIA  EQU   TARGET
MAPDS    DSECT
         DS    XL16
MFIELD   DS    F
TGTALIA  EQU   TARGET
MOFF     EQU   16
         END   ADDRQ
